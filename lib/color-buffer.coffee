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

  onDidDestroy: (callback) ->
    @emitter.on 'did-destroy', callback

  initialize: ->
    return @initializePromise if @initializePromise?

    # @project.initialize().then => @scanBuffer()
    @initializePromise = @scanBuffer().then (results) => @createMarkers(results)

  destroy: ->
    @subscriptions.dispose()
    @emitter.emit 'did-destroy'
    @destroyed = true

  getColorMarkers: -> @markers

  getValidColorMarkers: -> @getColorMarkers().filter (m) -> m.color.isValid()

  createMarkers: (results) ->
    return if @destroyed
    @markers = results.map (result) =>
      range = [
        @editor.getBuffer().positionForCharacterIndex(result.range[0])
        @editor.getBuffer().positionForCharacterIndex(result.range[1])
      ]
      marker = @editor.markBufferRange(range, type: 'pigments-color')
      new ColorMarker {marker, color: result.color}

  scanBuffer: ->
    return if @destroyed
    results = []
    taskPath = require.resolve('./tasks/scan-buffer-handler')

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
          res

  serialize: -> {editorId: @editor.id}
