[
  Color, ColorMarker, VariablesCollection,
  Emitter, CompositeDisposable, Task, Range,
  fs
] = []

module.exports =
class ColorBuffer
  constructor: (params={}) ->
    unless Emitter?
      {Emitter, CompositeDisposable, Task, Range} = require 'atom'

    {@editor, @project, colorMarkers} = params
    {@id} = @editor
    @emitter = new Emitter
    @subscriptions = new CompositeDisposable
    @ignoredScopes=[]

    @colorMarkersByMarkerId = {}

    @subscriptions.add @editor.onDidDestroy => @destroy()

    tokenized = =>
      @getColorMarkers()?.forEach (marker) ->
        marker.checkMarkerScope(true)

    if @editor.onDidTokenize?
      @subscriptions.add @editor.onDidTokenize(tokenized)
    else
      @subscriptions.add @editor.displayBuffer.onDidTokenize(tokenized)

    @subscriptions.add @editor.onDidChange =>
      @terminateRunningTask() if @initialized and @variableInitialized
      clearTimeout(@timeout) if @timeout?

    @subscriptions.add @editor.onDidStopChanging =>
      if @delayBeforeScan is 0
        @update()
      else
        clearTimeout(@timeout) if @timeout?
        @timeout = setTimeout =>
          @update()
          @timeout = null
        , @delayBeforeScan

    @subscriptions.add @editor.onDidChangePath (path) =>
      @project.appendPath(path) if @isVariablesSource()
      @update()

    if @project.getPaths()? and @isVariablesSource() and !@project.hasPath(@editor.getPath())
      fs ?= require 'fs'

      if fs.existsSync(@editor.getPath())
        @project.appendPath(@editor.getPath())
      else
        saveSubscription = @editor.onDidSave ({path}) =>
          @project.appendPath(path)
          @update()
          saveSubscription.dispose()
          @subscriptions.remove(saveSubscription)

        @subscriptions.add(saveSubscription)

    @subscriptions.add @project.onDidUpdateVariables =>
      return unless @variableInitialized
      @scanBufferForColors().then (results) => @updateColorMarkers(results)

    @subscriptions.add @project.onDidChangeIgnoredScopes =>
      @updateIgnoredScopes()

    @subscriptions.add atom.config.observe 'pigments.delayBeforeScan', (@delayBeforeScan=0) =>

    if @editor.addMarkerLayer?
      @markerLayer = @editor.addMarkerLayer()
    else
      @markerLayer = @editor

    if colorMarkers?
      @restoreMarkersState(colorMarkers)
      @cleanUnusedTextEditorMarkers()

    @updateIgnoredScopes()
    @initialize()

  onDidUpdateColorMarkers: (callback) ->
    @emitter.on 'did-update-color-markers', callback

  onDidDestroy: (callback) ->
    @emitter.on 'did-destroy', callback

  initialize: ->
    return Promise.resolve() if @colorMarkers?
    return @initializePromise if @initializePromise?

    @updateVariableRanges()

    @initializePromise = @scanBufferForColors().then (results) =>
      @createColorMarkers(results)
    .then (results) =>
      @colorMarkers = results
      @initialized = true

    @initializePromise.then => @variablesAvailable()

    @initializePromise

  restoreMarkersState: (colorMarkers) ->
    Color ?= require './color'
    ColorMarker ?= require './color-marker'

    @updateVariableRanges()

    @colorMarkers = colorMarkers
    .filter (state) -> state?
    .map (state) =>
      marker = @editor.getMarker(state.markerId) ? @markerLayer.markBufferRange(state.bufferRange, { invalidate: 'touch' })
      color = new Color(state.color)
      color.variables = state.variables
      color.invalid = state.invalid
      @colorMarkersByMarkerId[marker.id] = new ColorMarker {
        marker
        color
        text: state.text
        colorBuffer: this
      }

  cleanUnusedTextEditorMarkers: ->
    @markerLayer.findMarkers().forEach (m) =>
      m.destroy() unless @colorMarkersByMarkerId[m.id]?

  variablesAvailable: ->
    return @variablesPromise if @variablesPromise?

    @variablesPromise = @project.initialize()
    .then (results) =>
      return if @destroyed
      return unless results?

      @scanBufferForVariables() if @isIgnored() and @isVariablesSource()
    .then (results) =>
      @scanBufferForColors variables: results
    .then (results) =>
      @updateColorMarkers(results)
    .then =>
      @variableInitialized = true
    .catch (reason) ->
      console.log reason

  update: ->
    @terminateRunningTask()

    promise = if @isIgnored()
      @scanBufferForVariables()
    else unless @isVariablesSource()
      Promise.resolve([])
    else
      @project.reloadVariablesForPath(@editor.getPath())

    promise.then (results) =>
      @scanBufferForColors variables: results
    .then (results) =>
      @updateColorMarkers(results)
    .catch (reason) ->
      console.log reason

  terminateRunningTask: -> @task?.terminate()

  destroy: ->
    return if @destroyed

    @terminateRunningTask()
    @subscriptions.dispose()
    @colorMarkers?.forEach (marker) -> marker.destroy()
    @destroyed = true
    @emitter.emit 'did-destroy'
    @emitter.dispose()

  isVariablesSource: -> @project.isVariablesSourcePath(@editor.getPath())

  isIgnored: ->
    p = @editor.getPath()
    @project.isIgnoredPath(p) or not atom.project.contains(p)

  isDestroyed: -> @destroyed

  getPath: -> @editor.getPath()

  getScope: -> @project.scopeFromFileName(@getPath())

  updateIgnoredScopes: ->
    @ignoredScopes = @project.getIgnoredScopes().map (scope) ->
      try new RegExp(scope)
    .filter (re) -> re?

    @getColorMarkers()?.forEach (marker) -> marker.checkMarkerScope(true)
    @emitter.emit 'did-update-color-markers', {created: [], destroyed: []}


  ##    ##     ##    ###    ########   ######
  ##    ##     ##   ## ##   ##     ## ##    ##
  ##    ##     ##  ##   ##  ##     ## ##
  ##    ##     ## ##     ## ########   ######
  ##     ##   ##  ######### ##   ##         ##
  ##      ## ##   ##     ## ##    ##  ##    ##
  ##       ###    ##     ## ##     ##  ######

  updateVariableRanges: ->
    variablesForBuffer = @project.getVariablesForPath(@editor.getPath())
    variablesForBuffer.forEach (variable) =>
      variable.bufferRange ?= Range.fromObject [
        @editor.getBuffer().positionForCharacterIndex(variable.range[0])
        @editor.getBuffer().positionForCharacterIndex(variable.range[1])
      ]

  scanBufferForVariables: ->
    return Promise.reject("This ColorBuffer is already destroyed") if @destroyed
    return Promise.resolve([]) unless @editor.getPath()

    results = []
    taskPath = require.resolve('./tasks/scan-buffer-variables-handler')
    editor = @editor
    buffer = @editor.getBuffer()
    config =
      buffer: @editor.getText()
      registry: @project.getVariableExpressionsRegistry().serialize()
      scope: @getScope()

    new Promise (resolve, reject) =>
      @task = Task.once(
        taskPath,
        config,
        =>
          @task = null
          resolve(results)
      )

      @task.on 'scan-buffer:variables-found', (variables) ->
        results = results.concat variables.map (variable) ->
          variable.path = editor.getPath()
          variable.bufferRange = Range.fromObject [
            buffer.positionForCharacterIndex(variable.range[0])
            buffer.positionForCharacterIndex(variable.range[1])
          ]
          variable

  ##     ######   #######  ##        #######  ########
  ##    ##    ## ##     ## ##       ##     ## ##     ##
  ##    ##       ##     ## ##       ##     ## ##     ##
  ##    ##       ##     ## ##       ##     ## ########
  ##    ##       ##     ## ##       ##     ## ##   ##
  ##    ##    ## ##     ## ##       ##     ## ##    ##
  ##     ######   #######  ########  #######  ##     ##
  ##
  ##    ##     ##    ###    ########  ##    ## ######## ########   ######
  ##    ###   ###   ## ##   ##     ## ##   ##  ##       ##     ## ##    ##
  ##    #### ####  ##   ##  ##     ## ##  ##   ##       ##     ## ##
  ##    ## ### ## ##     ## ########  #####    ######   ########   ######
  ##    ##     ## ######### ##   ##   ##  ##   ##       ##   ##         ##
  ##    ##     ## ##     ## ##    ##  ##   ##  ##       ##    ##  ##    ##
  ##    ##     ## ##     ## ##     ## ##    ## ######## ##     ##  ######

  getMarkerLayer: -> @markerLayer

  getColorMarkers: -> @colorMarkers

  getValidColorMarkers: ->
    @getColorMarkers()?.filter((m) -> m.color?.isValid() and not m.isIgnored()) ? []

  getColorMarkerAtBufferPosition: (bufferPosition) ->
    markers = @markerLayer.findMarkers({
      containsBufferPosition: bufferPosition
    })

    for marker in markers
      if @colorMarkersByMarkerId[marker.id]?
        return @colorMarkersByMarkerId[marker.id]

  createColorMarkers: (results) ->
    return Promise.resolve([]) if @destroyed

    ColorMarker ?= require './color-marker'

    new Promise (resolve, reject) =>
      newResults = []

      processResults = =>
        startDate = new Date

        return resolve([]) if @editor.isDestroyed()

        while results.length
          result = results.shift()

          marker = @markerLayer.markBufferRange(result.bufferRange, {invalidate: 'touch'})
          newResults.push @colorMarkersByMarkerId[marker.id] = new ColorMarker {
            marker
            color: result.color
            text: result.match
            colorBuffer: this
          }

          if new Date() - startDate > 10
            requestAnimationFrame(processResults)
            return

        resolve(newResults)

      processResults()

  findExistingMarkers: (results) ->
    newMarkers = []
    toCreate = []

    new Promise (resolve, reject) =>
      processResults = =>
        startDate = new Date

        while results.length
          result = results.shift()

          if marker = @findColorMarker(result)
            newMarkers.push(marker)
          else
            toCreate.push(result)

          if new Date() - startDate > 10
            requestAnimationFrame(processResults)
            return

        resolve({newMarkers, toCreate})

      processResults()

  updateColorMarkers: (results) ->
    newMarkers = null
    createdMarkers = null

    @findExistingMarkers(results).then ({newMarkers: markers, toCreate}) =>
      newMarkers = markers
      @createColorMarkers(toCreate)
    .then (results) =>
      createdMarkers = results
      newMarkers = newMarkers.concat(results)

      if @colorMarkers?
        toDestroy = @colorMarkers.filter (marker) -> marker not in newMarkers
        toDestroy.forEach (marker) =>
          delete @colorMarkersByMarkerId[marker.id]
          marker.destroy()
      else
        toDestroy = []

      @colorMarkers = newMarkers
      @emitter.emit 'did-update-color-markers', {
        created: createdMarkers
        destroyed: toDestroy
      }

  findColorMarker: (properties={}) ->
    return unless @colorMarkers?
    for marker in @colorMarkers
      return marker if marker?.match(properties)

  findColorMarkers: (properties={}) ->
    markers = @markerLayer.findMarkers(properties)
    markers.map (marker) =>
      @colorMarkersByMarkerId[marker.id]
    .filter (marker) -> marker?

  findValidColorMarkers: (properties) ->
    @findColorMarkers(properties).filter (marker) =>
      marker? and marker.color?.isValid() and not marker?.isIgnored()

  selectColorMarkerAndOpenPicker: (colorMarker) ->
    return if @destroyed

    @editor.setSelectedBufferRange(colorMarker.marker.getBufferRange())

    # For the moment it seems only colors in #RRGGBB format are detected
    # by the color picker, so we'll exclude anything else
    return unless @editor.getSelectedText()?.match(/^#[0-9a-fA-F]{3,8}$/)

    if @project.colorPickerAPI?
      @project.colorPickerAPI.open(@editor, @editor.getLastCursor())

  scanBufferForColors: (options={}) ->
    return Promise.reject("This ColorBuffer is already destroyed") if @destroyed

    Color ?= require './color'

    results = []
    taskPath = require.resolve('./tasks/scan-buffer-colors-handler')
    buffer = @editor.getBuffer()
    registry = @project.getColorExpressionsRegistry().serialize()

    if options.variables?
      VariablesCollection ?= require './variables-collection'

      collection = new VariablesCollection()
      collection.addMany(options.variables)
      options.variables = collection

    variables = if @isVariablesSource()
      # In the case of files considered as source, the variables in the project
      # are needed when parsing the files.
      (options.variables?.getVariables() ? []).concat(@project.getVariables() ? [])
    else
      # Files that are not part of the sources will only use the variables
      # defined in them and so the global variables expression must be
      # discarded before sending the registry to the child process.
      options.variables?.getVariables() ? []

    delete registry.expressions['pigments:variables']
    delete registry.regexpString

    config =
      buffer: @editor.getText()
      bufferPath: @getPath()
      scope: @getScope()
      variables: variables
      colorVariables: variables.filter (v) -> v.isColor
      registry: registry

    new Promise (resolve, reject) =>
      @task = Task.once(
        taskPath,
        config,
        =>
          @task = null
          resolve(results)
      )

      @task.on 'scan-buffer:colors-found', (colors) ->
        results = results.concat colors.map (res) ->
          res.color = new Color(res.color)
          res.bufferRange = Range.fromObject [
            buffer.positionForCharacterIndex(res.range[0])
            buffer.positionForCharacterIndex(res.range[1])
          ]
          res

  serialize: ->
    {
      @id
      path: @editor.getPath()
      colorMarkers: @colorMarkers?.map (marker) ->
        marker.serialize()
    }
