{Emitter, CompositeDisposable, Task, Range} = require 'atom'
ProjectVariable = require './project-variable'
Color = require './color'
ColorMarker = require './color-marker'
VariableMarker = require './variable-marker'

module.exports =
class ColorBuffer
  constructor: (params={}) ->
    {@editor, @project, variableMarkers, colorMarkers} = params
    {@id} = @editor
    @emitter = new Emitter
    @subscriptions = new CompositeDisposable
    @ignoredScopes=[]

    @colorMarkersByMarkerId = {}
    @variableMarkersByMarkerId = {}

    @subscriptions.add @editor.onDidDestroy => @destroy()

    @subscriptions.add @editor.onDidChange =>
      @terminateRunningTask()
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
      resultsForBuffer = @project.getVariables().filter (r) =>
        r.path is @editor.getPath()
      @updateVariableMarkers(resultsForBuffer)

    @subscriptions.add atom.config.observe 'pigments.delayBeforeScan', (@delayBeforeScan=0) =>

    @subscriptions.add atom.config.observe 'pigments.ignoredScopes', (@ignoredScopes=[]) =>
      @emitter.emit 'did-update-color-markers', {created: [], destroyed: []}

    if variableMarkers? and colorMarkers?
      @restoreMarkersState(variableMarkers, colorMarkers)
      @cleanUnusedTextEditorMarkers()

    @initialize()

  onDidUpdateColorMarkers: (callback) ->
    @emitter.on 'did-update-color-markers', callback

  onDidUpdateVariableMarkers: (callback) ->
    @emitter.on 'did-update-variable-markers', callback

  onDidDestroy: (callback) ->
    @emitter.on 'did-destroy', callback

  initialize: ->
    return Promise.resolve() if @variableMarkers? and @colorMarkers?
    return @initializePromise if @initializePromise?

    @initializePromise = @scanBufferForColors().then (results) =>
      @colorMarkers = @createColorMarkers(results)

    @variablesAvailable()
    @initializePromise

  restoreMarkersState: (variableMarkers, colorMarkers) ->
    @variableMarkers = variableMarkers
    .filter (state) -> state?
    .map (state) =>
      bufferRange = Range.fromObject(state.bufferRange)
      marker = @editor.getMarker(state.markerId) ? @editor.markBufferRange(bufferRange, {
        type: 'pigments-variable'
        invalidate: 'touch'
      })
      variable = @project.getVariableByName(state.variable)
      variable.bufferRange ?= bufferRange
      @variableMarkersByMarkerId[marker.id] = new VariableMarker {marker, variable}

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
      }

  cleanUnusedTextEditorMarkers: ->
    @editor.findMarkers(type: 'pigments-color').forEach (m) =>
      m.destroy() unless @colorMarkersByMarkerId[m.id]?
    @editor.findMarkers(type: 'pigments-variable').forEach (m) =>
      m.destroy() unless @variableMarkersByMarkerId[m.id]?

  variablesAvailable: ->
    return @variablesPromise if @variablesPromise?

    @variablesPromise = @project.initialize()
    .then (results) =>
      return if @destroyed
      return unless results?

      resultsForBuffer = results.filter (r) => r.path is @editor.getPath()
      @variableMarkers = @createVariableMarkers(resultsForBuffer)

      @scanBufferForVariables() if @isIgnored() and @isVariablesSource()
    .then (results) =>
      @scanBufferForColors variables: results
    .then (results) =>
      @updateColorMarkers(results)
    .catch (reason) ->
      console.log reason

  update: ->
    promise = if @isIgnored()
      @scanBufferForVariables()
    else unless @isVariablesSource()
      Promise.resolve([])
    else
      @project.reloadVariablesForPath(@editor.getPath())

    promise.then (results) =>
      @scanBufferForColors
        variables: results?.map (p) => new ProjectVariable(p, @project)
    .then (results) =>
      @updateColorMarkers(results)
    .catch (reason) ->

  terminateRunningTask: -> @task?.terminate()

  destroy: ->
    @terminateRunningTask()
    @subscriptions.dispose()
    @emitter.emit 'did-destroy'
    @variableMarkers?.forEach (marker) -> marker.destroy()
    @colorMarkers?.forEach (marker) -> marker.destroy()
    @destroyed = true

  isVariablesSource: -> @project.isVariablesSourcePath(@editor.getPath())

  isIgnored: ->
    p = @editor.getPath()
    @project.isIgnoredPath(p) or not atom.project.contains(p)

  isDestroyed: -> @destroyed

  ##    ##     ##    ###    ########
  ##    ##     ##   ## ##   ##     ##
  ##    ##     ##  ##   ##  ##     ##
  ##    ##     ## ##     ## ########
  ##     ##   ##  ######### ##   ##
  ##      ## ##   ##     ## ##    ##
  ##       ###    ##     ## ##     ##
  ##
  ##    ##     ##    ###    ########  ##    ## ######## ########   ######
  ##    ###   ###   ## ##   ##     ## ##   ##  ##       ##     ## ##    ##
  ##    #### ####  ##   ##  ##     ## ##  ##   ##       ##     ## ##
  ##    ## ### ## ##     ## ########  #####    ######   ########   ######
  ##    ##     ## ######### ##   ##   ##  ##   ##       ##   ##         ##
  ##    ##     ## ##     ## ##    ##  ##   ##  ##       ##    ##  ##    ##
  ##    ##     ## ##     ## ##     ## ##    ## ######## ##     ##  ######

  getVariableMarkers: -> @variableMarkers

  getVariableMarkerByName: (name) ->
    return unless @variableMarkers?
    for marker in @variableMarkers
      return marker if marker.variable.name is name

  createVariableMarkers: (results) ->
    return if @destroyed
    results.map (result) =>
      bufferRange = Range.fromObject [
        @editor.getBuffer().positionForCharacterIndex(result.range[0])
        @editor.getBuffer().positionForCharacterIndex(result.range[1])
      ]
      result.bufferRange ?= bufferRange
      marker = @editor.markBufferRange(bufferRange, {
        type: 'pigments-variable'
        invalidate: 'touch'
      })
      @variableMarkersByMarkerId[marker.id] =
      new VariableMarker {marker, variable: result}

  updateVariableMarkers: (results) ->
    newMarkers = []
    toCreate = []
    for result in results
      if marker = @findVariableMarker(variable: result)
        newMarkers.push(marker)
      else
        toCreate.push(result)

    createdMarkers = @createVariableMarkers(toCreate)
    newMarkers = newMarkers.concat(createdMarkers)

    toDestroy = @variableMarkers?.filter((marker) -> marker not in newMarkers) ? []

    toDestroy.forEach (marker) -> marker.destroy()

    for id,marker of @variableMarkersByMarkerId when marker not in newMarkers
      delete @variableMarkersByMarkerId[id]

    @variableMarkers = newMarkers
    @emitter.emit 'did-update-variable-markers', {
      created: createdMarkers
      destroyed: toDestroy
    }

    @scanBufferForColors().then (results) => @updateColorMarkers(results)

  findVariableMarker: (properties={}) ->
    for marker in @variableMarkers
      return marker if marker.match(properties)

  findVariableMarkers: (properties={}) ->
    properties.type = 'pigments-variable'
    markers = @editor.findMarkers(properties)
    markers.map (marker) => @variableMarkersByMarkerId[marker.id]

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

  createColorMarkers: (results) ->
    return if @destroyed
    results.map (result) =>
      marker = @editor.markBufferRange(result.bufferRange, {
        type: 'pigments-color'
        invalidate: 'touch'
      })
      @colorMarkersByMarkerId[marker.id] =
      new ColorMarker {marker, color: result.color, text: result.match}

  updateColorMarkers: (results) ->
    newMarkers = []
    toCreate = []
    for result in results
      if marker = @findColorMarker(result)
        newMarkers.push(marker)
      else
        toCreate.push(result)

    createdMarkers = @createColorMarkers(toCreate)
    newMarkers = newMarkers.concat(createdMarkers)

    if @colorMarkers?
      toDestroy = @colorMarkers.filter (marker) -> marker not in newMarkers
      toDestroy.forEach (marker) -> marker.destroy()

      for id,marker of @colorMarkersByMarkerId when marker not in newMarkers
        delete @colorMarkersByMarkerId[id]

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
      marker?.color?.isValid() and not @markerScopeIsIgnored(marker)

  scanBufferForColors: (options={}) ->
    return Promise.reject("This ColorBuffer is already destroyed") if @destroyed
    results = []
    taskPath = require.resolve('./tasks/scan-buffer-colors-handler')
    buffer = @editor.getBuffer()
    variables = if @isVariablesSource()
      (options.variables ? []).concat(@project.getVariables() ? [])
    else
      options.variables ? []

    config =
      buffer: @editor.getText()
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

  markerScopeIsIgnored: (marker) ->
    range = marker.marker.getBufferRange()
    scope = @editor.displayBuffer.scopeDescriptorForBufferPosition(range.start)
    scopeChain = scope.getScopeChain()

    @ignoredScopes.some (scopeRegExp) ->
      try
        scopeChain.match(new RegExp(scopeRegExp))
      catch
        return false

  serialize: ->
    {
      @id
      path: @editor.getPath()
      variableMarkers: @variableMarkers?.map (marker) -> marker.serialize()
      colorMarkers: @colorMarkers?.map (marker) -> marker.serialize()
    }
