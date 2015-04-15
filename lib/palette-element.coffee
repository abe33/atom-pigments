{CompositeDisposable} = require 'atom'
{SpacePenDSL, EventsDelegation} = require 'atom-utils'
pigments = require './pigments'
Palette = require './palette'

class PaletteElement extends HTMLElement
  SpacePenDSL.includeInto(this)
  EventsDelegation.includeInto(this)

  @content: ->
    sort = atom.config.get('pigments.sortPaletteColors')
    group = atom.config.get('pigments.groupPaletteColors')
    optAttrs = (selected, attrs) ->
      attrs.selected = 'selected' if selected
      attrs

    @div class: 'palette-panel', =>
      @div class: 'palette-controls', =>
        @div class: 'palette-controls-wrapper', =>
          @span class: 'input-group-inline', =>
            @label for: 'sort-palette-colors', 'Sort Colors'
            @select outlet: 'sort', id: 'sort-palette-colors', =>
              @option optAttrs(sort is 'none', value: 'none'), 'None'
              @option optAttrs(sort is 'by name', value: 'by name'), 'By Name'
              @option optAttrs(sort is 'by file', value: 'by color'), 'By Color'

          @span class: 'input-group-inline', =>
            @label for: 'sort-palette-colors', 'Group Colors'
            @select outlet: 'group', id: 'group-palette-colors', =>
              @option optAttrs(group is 'none', value: 'none'), 'None'
              @option optAttrs(group is 'by file',  value: 'by file'), 'By File'

      @div class: 'palette-list', =>
        @ol outlet: 'list'

  createdCallback: ->
    @project = pigments.getProject()
    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.config.observe 'pigments.sortPaletteColors', (@sortPaletteColors) =>
      @renderList() if @palette?

    @subscriptions.add atom.config.observe 'pigments.groupPaletteColors', (@groupPaletteColors) =>
      @renderList() if @palette?

    @subscriptions.add @subscribeTo @sort, 'change': (e) ->
      atom.config.set 'pigments.sortPaletteColors', e.target.value

    @subscriptions.add @subscribeTo @group, 'change': (e) ->
      atom.config.set 'pigments.groupPaletteColors', e.target.value

  getTitle: -> 'Palette'

  getURI: -> 'pigments://palette'

  getIconName: -> "pigments"

  getModel: -> @palette

  setModel: (@palette) ->
    @renderList()

  getColorsList: (palette) ->
    switch @sortPaletteColors
      when 'by color' then palette.sortedByColor()
      when 'by name' then palette.sortedByName()
      else palette.tuple()

  renderList: ->
    @list.innerHTML = ''
    if @groupPaletteColors is 'by file'
      palettes = @getFilesPalettes()
      for file, palette of palettes
        li = document.createElement('li')
        li.className = 'color-group'
        ol = document.createElement('ol')

        li.appendChild @getGroupHeader(file)
        li.appendChild ol
        @buildList(ol, @getColorsList(palette))
        @list.appendChild(li)
    else
      @buildList(@list, @getColorsList(@palette))

  getGroupHeader: (label) ->
    header = document.createElement('div')
    header.className = 'color-group-header'
    header.textContent = label
    header

  getFilesPalettes: ->
    palettes = {}

    @palette.eachColor (name, color) =>
      {path} = @project.getVariableByName(name)

      palettes[path] ?= new Palette
      palettes[path].colors[name] = color

    palettes

  buildList: (container, paletteColors) ->
    for [name, color] in paletteColors
      li = document.createElement('li')
      li.className = 'color-item'
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
