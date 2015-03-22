{CompositeDisposable, Emitter} = require 'atom'

RENDERERS =
  background: require './renderers/background'
  outline: require './renderers/outline'
  underline: require './renderers/underline'

class ColorMarkerElement extends HTMLElement
  renderer: new RENDERERS.background

  createdCallback: ->
    @emitter = new Emitter
    @released = true

  attachedCallback: ->

  detachedCallback: ->
    @release()

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

    @subscriptions.add atom.config.observe 'pigments.markerType', (type) =>
      @render()

    @render()

  render: ->
    @innerHTML = ''
    {style, regions} = @renderer.render(@colorMarker)
    @appendChild(region) for region in regions
    if style?
      @style[k] = v for k,v of style
    else
      @style.cssText = ''

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
