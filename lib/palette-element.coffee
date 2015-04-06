{SpacePenDSL, EventsDelegation} = require 'atom-utils'
pigments = require './pigments'

class PaletteElement extends HTMLElement
  SpacePenDSL.includeInto(this)
  EventsDelegation.includeInto(this)

  @content: ->
    @div class: 'palette-panel', =>
      @div class: 'palette-controls'
      @div class: 'palette-list', =>
        @ol outlet: 'list'

  createdCallback: ->
    @project = pigments.getProject()

  getTitle: -> 'Palette'

  getURI: -> 'pigments://palette'

  getIconName: -> "pigments"

  getModel: -> @palette

  setModel: (@palette) ->
    @palette.eachColor (name, color) =>
      li = document.createElement('li')
      html = """
      <span class="pigments-color"
            style="background-color: #{color.toCSS()}">
      </span>
      <span class="pigments-color-details">
        <span class="name">#{name}</span>
      """
      if variable = @project.getVariableByName(name)
        html += """
        <span class="path">#{atom.project.relativize(variable.path)}</span>
        """

      html += '</span>'

      li.innerHTML = html

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
