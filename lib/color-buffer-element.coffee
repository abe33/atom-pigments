
class ColorBufferElement extends HTMLElement

  createdCallback: ->

  attachedCallback: ->

  detachedCallback: ->

  getModel: -> @colorBuffer

  setModel: (@colorBuffer) ->
    {@editor} = @colorBuffer

    @attach()

  attach: ->
    editorElement = atom.views.getView(@editor)
    editorElement.shadowRoot.querySelector('.lines').appendChild(this)

module.exports = ColorBufferElement =
document.registerElement 'pigments-markers', {
  prototype: ColorBufferElement.prototype
}

ColorBufferElement.registerViewProvider = (modelClass) ->
  atom.views.addViewProvider modelClass, (model) ->
    element = new ColorBufferElement
    element.setModel(model)
    element
