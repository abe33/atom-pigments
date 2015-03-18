
class ColorBufferElement extends HTMLElement

  createdCallback: ->

  attachedCallback: ->

  detachedCallback: ->

  getModel: -> @colorBuffer

  setModel: (@colorBuffer) ->

module.exports = ColorBufferElement =
document.registerElement 'pigments-markers', {
  prototype: ColorBufferElement.prototype
}

ColorBufferElement.registerViewProvider = (modelClass) ->
  atom.views.addViewProvider modelClass, (model) ->
    element = new ColorBufferElement
    element.setModel(model)
    element
