{CompositeDisposable} = require 'atom'

class ColorMarkerElement extends HTMLElement
  createdCallback: ->
  attachedCallback: ->
  detachedCallback: ->

module.exports = ColorMarkerElement =
document.registerElement 'pigments-color-marker', {
  prototype: ColorMarkerElement.prototype
}
