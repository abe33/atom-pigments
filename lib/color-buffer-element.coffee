{Emitter, CompositeDisposable} = require 'atom'
ColorMarkerElement = require './color-marker-element'

class ColorBufferElement extends HTMLElement

  createdCallback: ->
    @emitter = new Emitter
    @subscriptions = new CompositeDisposable
    @shadowRoot = @createShadowRoot()
    @displayedMarkers = []
    @usedMarkers = []
    @unusedMarkers = []

  attachedCallback: ->

  detachedCallback: ->

  onDidUpdate: (callback) ->
    @emitter.on 'did-update', callback

  getModel: -> @colorBuffer

  setModel: (@colorBuffer) ->
    {@editor} = @colorBuffer

    @colorBuffer.initialize().then => @updateMarkers()
    @subscriptions.add @colorBuffer.onDidUpdateColorMarkers => @updateMarkers()

    @attach()

  attach: ->
    @editorElement = atom.views.getView(@editor)
    @editorElement.shadowRoot.querySelector('.lines').appendChild(this)

  updateMarkers: ->
    markers = @colorBuffer.findColorMarkers({
      intersectsScreenRowRange: @editor.displayBuffer.getVisibleRowRange()
    }).filter (marker) -> marker.color?.isValid()

    for m in @displayedMarkers when m not in markers
      @releaseMarkerView(m)

    for m in markers when m.color.isValid() and m not in @displayedMarkers
      @requestMarkerView(m)

    @displayedMarkers = markers

    @emitter.emit 'did-update'

  requestMarkerView: (marker) ->
    if @unusedMarkers.length
      view = @unusedMarkers.shift()
      @usedMarkers.push(view)
      return view
    view = document.createElement('pigments-color-marker')
    @shadowRoot.appendChild view
    @usedMarkers.push(view)

  releaseMarkerView: (marker) ->
    view = @usedMarkers.shift()
    @unusedMarkers.push(view)

module.exports = ColorBufferElement =
document.registerElement 'pigments-markers', {
  prototype: ColorBufferElement.prototype
}

ColorBufferElement.registerViewProvider = (modelClass) ->
  atom.views.addViewProvider modelClass, (model) ->
    element = new ColorBufferElement
    element.setModel(model)
    element
