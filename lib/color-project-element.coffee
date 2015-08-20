{CompositeDisposable} = require 'atom'
{SpacePenDSL, EventsDelegation} = require 'atom-utils'

class ColorProjectElement extends HTMLElement
  SpacePenDSL.includeInto(this)
  EventsDelegation.includeInto(this)

  @content: ->

  createdCallback: ->

  setModel: (@project) ->

module.exports = ColorProjectElement =
document.registerElement 'pigments-color-project', {
  prototype: ColorProjectElement.prototype
}

ColorProjectElement.registerViewProvider = (modelClass) ->
  atom.views.addViewProvider modelClass, (model) ->
    element = new ColorProjectElement
    element.setModel(model)
    element
