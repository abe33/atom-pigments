{CompositeDisposable} = require 'atom'

module.exports =
class VariableMarker
  constructor: ({@marker, @variable}) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add @marker.onDidDestroy => @destroyed()

  destroy: ->
    return if @wasDestroyed
    @marker.destroy()

  destroyed: ->
    return if @wasDestroyed
    @subscriptions.dispose()
    {@marker, @variable} = {}
    @wasDestroyed = true
    @subscriptions = null

  match: (properties) ->
    bool = true

    if @marker? and properties.bufferRange?
      bool &&= @marker.getBufferRange().isEqual(properties.bufferRange)

    if properties.variable? && @variable?
      bool &&= @isEqual(@variable, properties.variable)

    bool

  isEqual: (v1, v2) ->
    bool = v1.name is v2.name and
    v1.value is v2.value and
    v1.path is v2.path

    bool &&= if v1.bufferRange? and v2.bufferRange?
      v1.bufferRange.isEqual(v2.bufferRange)
    else
      v1.range[0] is v2.range[0] and v1.range[1] is v2.range[1]

    bool

  serialize: ->
    return if @wasDestroyed
    {
      markerId: String(@marker.id)
      bufferRange: @marker.getBufferRange().serialize()
      variable: @variable.name
    }
