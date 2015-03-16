{CompositeDisposable} = require 'atom'

module.exports =
class VariableMarker
  constructor: ({@marker, @variable}) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add @marker.onDidDestroy => @destroyed()
    @subscriptions.add @variable.onDidDestroy => @destroy()

  destroy: ->
    return if @wasDestroyed
    @marker.destroy()

  destroyed: ->
    return if @wasDestroyed
    @subscriptions.dispose()
    {@marker, @variable} = {}
    @wasDestroyed = true

  match: (properties) ->
    bool = true

    if properties.bufferRange?
      bool &&= @marker?.getBufferRange().isEqual(properties.bufferRange)

    if properties.variable
      bool &&= @variable?.isEqual(properties.variable)

    bool
