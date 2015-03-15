{Emitter, CompositeDisposable, Task} = require 'atom'
Color = require './color'
ColorMarker = require './color-marker'

module.exports =
class ColorBuffer
  constructor: (params={}) ->
    {@editor, @project} = params
    @emitter = new Emitter
    @subscriptions = new CompositeDisposable

    @subscriptions.add @editor.onDidDestroy => @destroy()

    @initialize()

  onDidUpdateMarkers: (callback) ->
    @emitter.on 'did-update-markers', callback

  onDidDestroy: (callback) ->
    @emitter.on 'did-destroy', callback

  initialize: ->
    return @initializePromise if @initializePromise?

    @initializePromise = @scanBuffer().then (results) =>
      @markers = @createMarkers(results)

    @project.initialize().then =>
      return if @destroyed

      @scanBuffer().then (results) => @updateMarkers(results)

    @initializePromise

  destroy: ->
    @subscriptions.dispose()
    @emitter.emit 'did-destroy'
    @destroyed = true

  getColorMarkers: -> @markers

  getValidColorMarkers: -> @getColorMarkers().filter (m) -> m.color.isValid()

  createMarkers: (results) ->
    return if @destroyed
    results.map (result) =>
      marker = @editor.markBufferRange(result.bufferRange, type: 'pigments-color')
      new ColorMarker {marker, color: result.color, text: result.match}

  updateMarkers: (results) ->
    newMarkers = []
    toCreate = []
    for result in results
      if marker = @findMarker(result)
        newMarkers.push(marker)
      else
        toCreate.push(result)

    createdMarkers = @createMarkers(toCreate)
    newMarkers = newMarkers.concat(createdMarkers)

    toDestroy = @markers.filter (marker) -> marker not in newMarkers
    toDestroy.forEach (marker) -> marker.destroy()

    @markers = newMarkers
    @emitter.emit 'did-update-markers', {
      created: createdMarkers
      destroyed: toDestroy
    }

  findMarker: (properties) ->
    for marker in @markers
      return marker if marker.match(properties)

  scanBuffer: ->
    return if @destroyed
    results = []
    taskPath = require.resolve('./tasks/scan-buffer-handler')
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
