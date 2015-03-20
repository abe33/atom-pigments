{CompositeDisposable, Emitter} = require 'atom'

class ColorMarkerElement extends HTMLElement

  createdCallback: ->
    @emitter = new Emitter
    @released = true

  attachedCallback: ->

  detachedCallback: ->

  onDidRelease: (callback) ->
    @emitter.on 'did-release', callback

  getModel: -> @colorMarker

  setModel: (@colorMarker) ->
    return unless @released
    @released = false
    @subscriptions = new CompositeDisposable
    @subscriptions.add @colorMarker.marker.onDidDestroy => @release()

  isReleased: -> @released

  release: (dispatchEvent=true) ->
    return if @released
    @subscriptions.dispose()
    @subscriptions = null
    @colorMarker = null
    @released = true
    @emitter.emit('did-release') if dispatchEvent

module.exports = ColorMarkerElement =
document.registerElement 'pigments-color-marker', {
  prototype: ColorMarkerElement.prototype
}
