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

    @subscriptions.add atom.config.observe 'pigments.delayBeforeScan', (@delayBeforeScan=0) =>

    @subscriptions.add atom.config.observe 'pigments.ignoredScopes', (@ignoredScopes=[]) =>
      @emitter.emit 'did-update-color-markers', {created: [], destroyed: []}

    # Needed to clean the serialized markers from previous versions
    @editor.findMarkers(type: 'pigments-variable').forEach (m) -> m.destroy()

    if colorMarkers?
      @restoreMarkersState(colorMarkers)
      @cleanUnusedTextEditorMarkers()

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
      @colorMarkers = @createColorMarkers(results)
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
    @terminateRunningTask()
    @subscriptions.dispose()
    @emitter.emit 'did-destroy'
    @colorMarkers?.forEach (marker) -> marker.destroy()
    @destroyed = true

  isVariablesSource: -> @project.isVariablesSourcePath(@editor.getPath())

  isIgnored: ->
    p = @editor.getPath()
    @project.isIgnoredPath(p) or not atom.project.contains(p)

  isDestroyed: -> @destroyed

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

  colorMarkerForMouseEvent: (event) ->
    position = @screenPositionForMouseEvent(event)
    bufferPosition = @displayBuffer.bufferPositionForScreenPosition(position)

    @getColorMarkerAtBufferPosition(bufferPosition)

  screenPositionForMouseEvent: (event) ->
    pixelPosition = @pixelPositionForMouseEvent(event)
    @editor.screenPositionForPixelPosition(pixelPosition)

  pixelPositionForMouseEvent: (event) ->
    {clientX, clientY} = event

    editorElement = atom.views.getView(@editor)
    rootElement = editorElement.shadowRoot ? editorElement
    {top, left} = rootElement.querySelector('.lines').getBoundingClientRect()
    top = clientY - top + @editor.getScrollTop()
    left = clientX - left + @editor.getScrollLeft()
    {top, left}

  findValidColorMarkers: (properties) ->
    @findColorMarkers(properties).filter (marker) =>
      marker?.color?.isValid() and not @markerScopeIsIgnored(marker)

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
    try
      scope = @editor.displayBuffer.scopeDescriptorForBufferPosition(range.start)
      scopeChain = scope.getScopeChain()

      @ignoredScopes.some (scopeRegExp) ->
        try
          scopeChain.match(new RegExp(scopeRegExp))
        catch
          return false
    catch e
      console.warn "Unable to find a scope at the given buffer position", @editor

  serialize: ->
    {
      @id
      path: @editor.getPath()
      colorMarkers: @colorMarkers?.map (marker) ->
        marker.serialize()
    }
