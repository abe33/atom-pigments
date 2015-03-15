{CompositeDisposable} = require 'atom'

module.exports =
class ColorMarker
  constructor: ({@marker, @color, @text}) ->
    @subscriptions = new CompositeDisposable
    @subscriptions = @marker.onDidDestroy => @destroyed()

  destroy: ->
    @marker.destroy()

  destroyed: ->
    @subscriptions.dispose()
    {@marker, @color, @text} = {}

  match: (properties) ->
    bool = true

    if properties.bufferRange?
      bool &&= @marker.getBufferRange().isEqual(properties.bufferRange)
    bool &&= properties.color.isEqual(@color) if properties.color?
    bool &&= properties.match is @text if properties.match?
    bool &&= properties.text is @text if properties.text?

    bool
