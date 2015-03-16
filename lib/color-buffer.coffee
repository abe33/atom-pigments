{Emitter, CompositeDisposable, Task} = require 'atom'
Color = require './color'
ColorMarker = require './color-marker'
VariableMarker = require './variable-marker'

module.exports =
class ColorBuffer
  constructor: (params={}) ->
    {@editor, @project} = params
    @emitter = new Emitter
    @subscriptions = new CompositeDisposable

    @subscriptions.add @editor.onDidDestroy => @destroy()

    @initialize()

  onDidUpdateColorMarkers: (callback) ->
    @emitter.on 'did-update-color-markers', callback

  onDidUpdateVariableMarkers: (callback) ->
    @emitter.on 'did-update-variable-markers', callback

  onDidDestroy: (callback) ->
    @emitter.on 'did-destroy', callback

  initialize: ->
    return @initializePromise if @initializePromise?

    @initializePromise = @scanBufferForColors().then (results) =>
      @colorMarkers = @createColorMarkers(results)

    @project.initialize().then (results) =>
      return if @destroyed
      return unless results?

      resultsForBuffer = results.filter (r) => r.path is @editor.getPath()
      @variableMarkers = @createVariableMarkers(resultsForBuffer)

      @scanBufferForColors().then (results) => @updateColorMarkers(results)

    @initializePromise

  destroy: ->
    @subscriptions.dispose()
    @emitter.emit 'did-destroy'
    @destroyed = true

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

  createVariableMarkers: (results) ->
    return if @destroyed
    results.map (result) =>
      bufferRange = [
        @editor.getBuffer().positionForCharacterIndex(result.range[0])
        @editor.getBuffer().positionForCharacterIndex(result.range[1])
      ]
      marker = @editor.markBufferRange(bufferRange, {
        type: 'pigments-variable'
        invalidate: 'touch'
      })
      new VariableMarker {marker, variable: result}

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

    toDestroy = @colorMarkers.filter (marker) -> marker not in newMarkers
    toDestroy.forEach (marker) -> marker.destroy()

    @colorMarkers = newMarkers
    @emitter.emit 'did-update-color-markers', {
      created: createdMarkers
      destroyed: toDestroy
    }

  findColorMarker: (properties) ->
    for marker in @colorMarkers
      return marker if marker.match(properties)

  scanBufferForVariables: ->
    return if @destroyed
    results = []
    taskPath = require.resolve('./tasks/scan-buffer-variables-handler')
    buffer = @editor.getBuffer()
    config =
      buffer: @editor.getText()

    new Promise (resolve, reject) ->
      task = Task.once(
        taskPath,
        config,
        -> resolve(results)
      )

      task.on 'scan-buffer:variables-found', (variables) ->
        results = results.concat variables

  scanBufferForColors: ->
    return if @destroyed
    results = []
    taskPath = require.resolve('./tasks/scan-buffer-colors-handler')
    buffer = @editor.getBuffer()
    config =
      buffer: @editor.getText()
      variables: @project.getVariables()?.map (v) -> v.serialize()

    new Promise (resolve, reject) ->
      task = Task.once(
        taskPath,
        config,
        -> resolve(results)
      )

      task.on 'scan-buffer:colors-found', (colors) ->
        results = results.concat colors.map (res) ->
          res.color = new Color(res.color)
          res.bufferRange = [
            buffer.positionForCharacterIndex(res.range[0])
            buffer.positionForCharacterIndex(res.range[1])
          ]
          res

  serialize: -> {editorId: @editor.id}
