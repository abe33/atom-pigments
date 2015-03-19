{CompositeDisposable} = require 'atom'

class ColorBufferElement extends HTMLElement

  createdCallback: ->
    @subscriptions = new CompositeDisposable
    @shadowRoot = @createShadowRoot()

  attachedCallback: ->

  detachedCallback: ->

  getModel: -> @colorBuffer

  setModel: (@colorBuffer) ->
    {@editor} = @colorBuffer

    @colorBuffer.initialize().then => @createMarkers()

    @attach()

  attach: ->
    @editorElement = atom.views.getView(@editor)
    @editorElement.shadowRoot.querySelector('.lines').appendChild(this)

  createMarkers: ->
    markers = @colorBuffer.findColorMarkers intersectsScreenRowRange: @editor.displayBuffer.getVisibleRowRange()
    for m in markers when m.color?
      @shadowRoot.appendChild document.createElement('pigments-color-marker')


module.exports = ColorBufferElement =
document.registerElement 'pigments-markers', {
  prototype: ColorBufferElement.prototype
}

ColorBufferElement.registerViewProvider = (modelClass) ->
  atom.views.addViewProvider modelClass, (model) ->
    element = new ColorBufferElement
    element.setModel(model)
    element
