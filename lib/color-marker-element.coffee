{CompositeDisposable, Emitter} = require 'atom'

class ColorMarkerElement extends HTMLElement

  createdCallback: ->
    @emitter = new Emitter

  attachedCallback: ->

  detachedCallback: ->

  onDidRelease: (callback) ->
    @emitter.on 'did-release', callback

  getModel: -> @colorMarker

  setModel: (@colorMarker) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add @colorMarker.marker.onDidDestroy => @release()

  release: ->
    @subscriptions.dispose()
    @subscriptions = null
    @colorMarker = null
    @emitter.emit 'did-release'

module.exports = ColorMarkerElement =
document.registerElement 'pigments-color-marker', {
  prototype: ColorMarkerElement.prototype
}
