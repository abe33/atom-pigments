{CompositeDisposable} = require 'atom'
{SpacePenDSL, EventsDelegation} = require 'atom-utils'
pigments = require './pigments'

class PaletteElement extends HTMLElement
  SpacePenDSL.includeInto(this)
  EventsDelegation.includeInto(this)

  @content: ->
    @div class: 'palette-panel', =>
      @div class: 'palette-controls', =>
        @div class: 'palette-controls-wrapper', =>
          @label for: 'sort-palette-colors', 'Sort'
          @select outlet: 'sort', id: 'sort-palette-colors', =>
            @option value: 'none', 'None'
            @option value: 'by name', 'By Name'
            @option value: 'by color', 'By Color'

      @div class: 'palette-list', =>
        @ol outlet: 'list'

  createdCallback: ->
    @project = pigments.getProject()
    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.config.observe 'pigments.sortPaletteColors', (@sortPaletteColors) =>
      @renderList() if @palette?

  getTitle: -> 'Palette'

  getURI: -> 'pigments://palette'

  getIconName: -> "pigments"

  getModel: -> @palette

  setModel: (@palette) ->
    @renderList()

  getColorsList: ->
    switch @sortPaletteColors
      when 'by color' then @palette.sortedByColor()
      when 'by name' then @palette.sortedByName()
      else @palette.tuple()

  renderList: ->
    @buildList(@list, @getColorsList())

  buildList: (container, paletteColors) ->
    container.innerHTML = ''
    for [name, color] in paletteColors
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

      container.appendChild(li)

module.exports = PaletteElement =
document.registerElement 'pigments-palette', {
  prototype: PaletteElement.prototype
}

PaletteElement.registerViewProvider = (modelClass) ->
  atom.views.addViewProvider modelClass, (model) ->
    element = new PaletteElement
    element.setModel(model)
    element
