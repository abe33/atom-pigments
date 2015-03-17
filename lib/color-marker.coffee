{CompositeDisposable} = require 'atom'

module.exports =
class ColorMarker
  constructor: ({@marker, @color, @text}) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add @marker.onDidDestroy => @destroyed()
    @subscriptions.add @marker.onDidChange =>
      @destroy() unless @marker.isValid()

  destroy: ->
    return if @wasDestroyed
    @marker.destroy()

  destroyed: ->
    return if @wasDestroyed
    @subscriptions.dispose()
    {@marker, @color, @text} = {}
    @wasDestroyed = true

  match: (properties) ->
    return false if @wasDestroyed

    bool = true

    if properties.bufferRange?
      bool &&= @marker.getBufferRange().isEqual(properties.bufferRange)
    bool &&= properties.color.isEqual(@color) if properties.color?
    bool &&= properties.match is @text if properties.match?
    bool &&= properties.text is @text if properties.text?

    bool

  serialize: ->
    return if @wasDestroyed
    {
      bufferRange: @marker.getBufferRange().serialize()
      color: @color.serialize()
      text: @text
      variables: @color.variables
    }
