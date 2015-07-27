{CompositeDisposable} = require 'atom'
{fill} = require './utils'

module.exports =
class ColorMarker
  constructor: ({@marker, @color, @text, @invalid, @colorBuffer}) ->
    @id = @marker.id
    @subscriptions = new CompositeDisposable
    @subscriptions.add @marker.onDidDestroy => @markerWasDestroyed()
    @subscriptions.add @marker.onDidChange =>
      if @marker.isValid()
        @checkMarkerScope()
      else
        @destroy()

    @checkMarkerScope()

  destroy: ->
    return if @destroyed
    @marker.destroy()

  markerWasDestroyed: ->
    return if @destroyed
    @subscriptions.dispose()
    {@marker, @color, @text, @colorBuffer} = {}
    @destroyed = true

  match: (properties) ->
    return false if @destroyed

    bool = true

    if properties.bufferRange?
      bool &&= @marker.getBufferRange().isEqual(properties.bufferRange)
    bool &&= properties.color.isEqual(@color) if properties.color?
    bool &&= properties.match is @text if properties.match?
    bool &&= properties.text is @text if properties.text?

    bool

  serialize: ->
    return if @destroyed
    out = {
      markerId: String(@marker.id)
      bufferRange: @marker.getBufferRange().serialize()
      color: @color.serialize()
      text: @text
      variables: @color.variables
    }
    out.invalid = true unless @color.isValid()
    out

  checkMarkerScope: (forceEvaluation=false) ->
    return if @destroyed
    range = @marker.getBufferRange()

    try
      scope = @marker.displayBuffer.scopeDescriptorForBufferPosition(range.start)
      scopeChain = scope.getScopeChain()

      return if not scopeChain or (!forceEvaluation and scopeChain is @lastScopeChain)

      @ignored = @colorBuffer.ignoredScopes.some (scopeRegExp) ->
        scopeChain.match(scopeRegExp)


      @lastScopeChain = scopeChain
    catch e
      console.error e

  isIgnored: -> @ignored

  convertContentToHex: ->
    hex = '#' + fill(@color.hex, 6)

    @marker.displayBuffer.buffer.setTextInRange(@marker.getBufferRange(), hex)

  convertContentToRGBA: ->
    if @color.alpha is 1
      rgba = "rgb(#{Math.round @color.red}, #{Math.round @color.green}, #{Math.round @color.blue})"
    else
      rgba = "rgba(#{Math.round @color.red}, #{Math.round @color.green}, #{Math.round @color.blue}, #{@color.alpha})"

    @marker.displayBuffer.buffer.setTextInRange(@marker.getBufferRange(), rgba)
