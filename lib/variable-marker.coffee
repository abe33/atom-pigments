{CompositeDisposable} = require 'atom'

module.exports =
class VariableMarker
  constructor: ({@marker, @variable}) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add @marker.onDidDestroy => @destroyed()
    @subscriptions.add @marker.onDidChange =>
      @variable.destroy() unless @marker.isValid()
    @subscriptions.add @variable.onDidDestroy => @destroy()

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
