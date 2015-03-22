{CompositeDisposable, Emitter} = require 'atom'

RENDERERS =
  background: require './renderers/background'

class ColorMarkerElement extends HTMLElement
  renderer: new RENDERERS.background

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
    @subscriptions.add @colorMarker.marker.onDidChange ({isValid}) =>
      if isValid then @render() else @release()

    @render()

  render: ->
    @innerHTML = ''
    content = @renderer.render(@colorMarker)
    @appendChild(node) for node in content

  isReleased: -> @released

  release: (dispatchEvent=true) ->
    return if @released
    @subscriptions.dispose()
    @subscriptions = null
    @colorMarker = null
    @released = true
    @innerHTML = ''
    @emitter.emit('did-release') if dispatchEvent

module.exports = ColorMarkerElement =
document.registerElement 'pigments-color-marker', {
  prototype: ColorMarkerElement.prototype
}

ColorMarkerElement.setMarkerType = (markerType) ->
  @prototype.renderer = new RENDERERS[markerType]
