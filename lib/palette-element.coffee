{SpacePenDSL, EventsDelegation} = require 'atom-utils'

class PaletteElement extends HTMLElement
  SpacePenDSL.includeInto(this)
  EventsDelegation.includeInto(this)

  @content: ->
    @div class: 'palette-panel', =>
      @div class: 'palette-controls'
      @div class: 'palette-list', =>
        @ol outlet: 'list'

  getTitle: -> 'Palette'

  getURI: -> 'pigments://palette'

  getIconName: -> "pigments"

  getModel: -> @palette

  setModel: (@palette) ->
    @palette.eachColor (name, color) =>
      li = document.createElement('li')
      li.innerHTML = """
      <span class="pigments-color"
            style="background-color: #{color.toCSS()}">
      </span>
      <span class="name">#{name}</span>
      """
      @list.appendChild(li)

module.exports = PaletteElement =
document.registerElement 'pigments-palette', {
  prototype: PaletteElement.prototype
}

PaletteElement.registerViewProvider = (modelClass) ->
  atom.views.addViewProvider modelClass, (model) ->
    element = new PaletteElement
    element.setModel(model)
    element
