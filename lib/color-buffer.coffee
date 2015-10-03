{Emitter, CompositeDisposable, Task, Range} = require 'atom'
Color = require './color'
ColorMarker = require './color-marker'
VariablesCollection = require './variables-collection'

module.exports =
class ColorBuffer
  constructor: (params={}) ->
    {@editor, @project, colorMarkers} = params
    {@id, @displayBuffer} = @editor
    @emitter = new Emitter
    @subscriptions = new CompositeDisposable
    @ignoredScopes=[]

    @colorMarkersByMarkerId = {}

    @subscriptions.add @editor.onDidDestroy => @destroy()
    @subscriptions.add @editor.displayBuffer.onDidTokenize =>
      @getColorMarkers()?.forEach (marker) ->
        marker.checkMarkerScope(true)

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

    @subscriptions.add @project.onDidUpdateVariables =>
      return unless @variableInitialized
      @scanBufferForColors().then (results) => @updateColorMarkers(results)

    @subscriptions.add @project.onDidChangeIgnoredScopes =>
      @updateIgnoredScopes()

    @subscriptions.add atom.config.observe 'pigments.delayBeforeScan', (@delayBeforeScan=0) =>

    # Needed to clean the serialized markers from previous versions
    @editor.findMarkers(type: 'pigments-variable').forEach (m) -> m.destroy()

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
    @updateVariableRanges()

    @colorMarkers = colorMarkers
    .filter (state) -> state?
    .map (state) =>
      marker = @editor.getMarker(state.markerId) ? @editor.markBufferRange(state.bufferRange, {
        type: 'pigments-color'
        invalidate: 'touch'
      })
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
    @editor.findMarkers(type: 'pigments-color').forEach (m) =>
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
    results = []
    taskPath = require.resolve('./tasks/scan-buffer-variables-handler')
    editor = @editor
    buffer = @editor.getBuffer()
    config =
      buffer: @editor.getText()

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

  getColorMarkers: -> @colorMarkers

  getValidColorMarkers: -> @getColorMarkers().filter (m) -> m.color.isValid()

  getColorMarkerAtBufferPosition: (bufferPosition) ->
    markers = @editor.findMarkers({
      type: 'pigments-color'
      containsBufferPosition: bufferPosition
    })

    for marker in markers
      if @colorMarkersByMarkerId[marker.id]?
        return @colorMarkersByMarkerId[marker.id]

  createColorMarkers: (results) ->
    return Promise.resolve([]) if @destroyed

    new Promise (resolve, reject) =>
      newResults = []

      processResults = =>
        startDate = new Date

        return resolve([]) if @editor.isDestroyed()

        while results.length
          result = results.shift()

          marker = @editor.markBufferRange(result.bufferRange, {
            type: 'pigments-color'
            invalidate: 'touch'
          })
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
    properties.type = 'pigments-color'
    markers = @editor.findMarkers(properties)
    markers.map (marker) =>
      @colorMarkersByMarkerId[marker.id]
    .filter (marker) -> marker?

  findValidColorMarkers: (properties) ->
    @findColorMarkers(properties).filter (marker) =>
      marker? and marker.color?.isValid() and not marker?.isIgnored()

  scanBufferForColors: (options={}) ->
    return Promise.reject("This ColorBuffer is already destroyed") if @destroyed
    results = []
    taskPath = require.resolve('./tasks/scan-buffer-colors-handler')
    buffer = @editor.getBuffer()

    if options.variables?
      collection = new VariablesCollection()
      collection.addMany(options.variables)
      options.variables = collection

    variables = if @isVariablesSource()
      (options.variables?.getVariables() ? []).concat(@project.getVariables() ? [])
    else
      options.variables?.getVariables() ? []

    config =
      buffer: @editor.getText()
      bufferPath: @getPath()
      variables: variables
      colorVariables: variables.filter (v) -> v.isColor

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
