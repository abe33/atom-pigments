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

  match: (properties) ->
    bool = true

    if properties.bufferRange?
      bool &&= @marker?.bufferRange.isEqual(properties.bufferRange)

    if properties.variable? && @variables?
      bool &&= @isEqual(@variable, properties.variable)

    bool

  isEqual: (v1, v2) ->
    bool = v1.name is v2.name and
    v1.value is v2.value and
    v1.path is v2.path

    bool &&= if v1.bufferRange? and v2.bufferRange?
      v1.bufferRange.isEqual(v2.bufferRange)
    else
      v1range[0] is v2.range[0] and v1range[1] is v2.range[1]

    bool

  serialize: ->
    return if @wasDestroyed
    {
      markerId: String(@marker.id)
      bufferRange: @marker.bufferRange.serialize()
      variable: @variable.name
    }
