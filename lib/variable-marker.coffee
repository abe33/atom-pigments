{CompositeDisposable} = require 'atom'

module.exports =
class VariableMarker
  constructor: ({@marker, @variable}) ->
    @subscriptions = new CompositeDisposable
    @subscriptions = @marker.onDidDestroy => @destroyed()

  destroy: ->
    @marker.destroy()

  destroyed: ->
    @subscriptions.dispose()
    {@marker, @variable} = {}

  match: (properties) ->
    bool = true

    if properties.bufferRange?
      bool &&= @marker.getBufferRange().isEqual(properties.bufferRange)

    bool
