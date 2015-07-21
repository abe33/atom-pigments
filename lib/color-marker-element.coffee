{CompositeDisposable, Emitter} = require 'atom'

RENDERERS =
  'background': require './renderers/background'
  'outline': require './renderers/outline'
  'underline': require './renderers/underline'
  'dot': require './renderers/dot'
  'square-dot': require './renderers/square-dot'

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
    @subscriptions.add @colorMarker.marker.onDidChange (data) =>
      {isValid} = data
      if isValid then @render() else @release()

    @subscriptions.add atom.config.observe 'pigments.markerType', (type) =>
      @render()

    @render()

  destroy: ->
    @parentNode?.removeChild(this)
    @subscriptions?.dispose()
    @clear()

  render: ->
    @innerHTML = ''
    {style, regions, class: cls} = @renderer.render(@colorMarker)

    @appendChild(region) for region in regions if regions?
    if cls?
      classes = cls.split(' ')
      @classList.add(cls) for cls in classes

    if style?
      @style[k] = v for k,v of style
    else
      @style.cssText = ''

    @lastMarkerScreenRange = @colorMarker.marker.getScreenRange()

  checkScreenRange: ->
    unless @lastMarkerScreenRange.isEqual(@colorMarker.marker.getScreenRange())
      @render()

  isReleased: -> @released

  release: (dispatchEvent=true) ->
    return if @released
    @subscriptions.dispose()
    marker = @colorMarker
    @clear()
    @emitter.emit('did-release', {marker, view: this}) if dispatchEvent

  clear: ->
    @subscriptions = null
    @colorMarker = null
    @released = true
    @innerHTML = ''
    @className = ''
    @style.cssText = ''

module.exports = ColorMarkerElement =
document.registerElement 'pigments-color-marker', {
  prototype: ColorMarkerElement.prototype
}

ColorMarkerElement.setMarkerType = (markerType) ->
  @prototype.renderer = new RENDERERS[markerType]
