{CompositeDisposable} = require 'atom'
{SpacePenDSL, EventsDelegation} = require 'atom-utils'
pigments = require './pigments'
Palette = require './palette'
StickyTitle = require './sticky-title'

class PaletteElement extends HTMLElement
  SpacePenDSL.includeInto(this)
  EventsDelegation.includeInto(this)

  @content: ->
    sort = atom.config.get('pigments.sortPaletteColors')
    group = atom.config.get('pigments.groupPaletteColors')
    merge = atom.config.get('pigments.mergeColorDuplicates')
    optAttrs = (bool, name, attrs) ->
      attrs[name] = name if bool
      attrs

    @div class: 'pigments-palette-panel', =>
      @div class: 'pigments-palette-controls settings-view pane-item', =>
        @div class: 'pigments-palette-controls-wrapper', =>
          @span class: 'input-group-inline', =>
            @label for: 'sort-palette-colors', 'Sort Colors'
            @select outlet: 'sort', id: 'sort-palette-colors', =>
              @option optAttrs(sort is 'none', 'selected', value: 'none'), 'None'
              @option optAttrs(sort is 'by name', 'selected', value: 'by name'), 'By Name'
              @option optAttrs(sort is 'by file', 'selected', value: 'by color'), 'By Color'

          @span class: 'input-group-inline', =>
            @label for: 'sort-palette-colors', 'Group Colors'
            @select outlet: 'group', id: 'group-palette-colors', =>
              @option optAttrs(group is 'none', 'selected', value: 'none'), 'None'
              @option optAttrs(group is 'by file', 'selected', value: 'by file'), 'By File'

          @span class: 'input-group-inline', =>
            @input optAttrs merge, 'checked', type: 'checkbox', id: 'merge-duplicates', outlet: 'merge'
            @label for: 'merge-duplicates', 'Merge Duplicates'

      @div class: 'pigments-palette-list native-key-bindings', tabindex: -1, =>
        @ol outlet: 'list'

  createdCallback: ->
    @project = pigments.getProject()
    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.config.observe 'pigments.sortPaletteColors', (@sortPaletteColors) =>
      @renderList() if @palette? and @attached

    @subscriptions.add atom.config.observe 'pigments.groupPaletteColors', (@groupPaletteColors) =>
      @renderList() if @palette? and @attached

    @subscriptions.add atom.config.observe 'pigments.mergeColorDuplicates', (@mergeColorDuplicates) =>
      @renderList() if @palette? and @attached

    @subscriptions.add @subscribeTo @sort, 'change': (e) ->
      atom.config.set 'pigments.sortPaletteColors', e.target.value

    @subscriptions.add @subscribeTo @group, 'change': (e) ->
      atom.config.set 'pigments.groupPaletteColors', e.target.value

    @subscriptions.add @subscribeTo @merge, 'change': (e) ->
      atom.config.set 'pigments.mergeColorDuplicates', e.target.checked

    @subscriptions.add @subscribeTo @list, '[data-variable-id]', 'click': (e) =>
      variableId = Number(e.target.dataset.variableId)
      variable = @project.getVariableById(variableId)

      @project.showVariableInFile(variable)

  attachedCallback: ->
    @renderList() if @palette?
    @attached = true

  getTitle: -> 'Palette'

  getURI: -> 'pigments://palette'

  getIconName: -> "pigments"

  getModel: -> @palette

  setModel: (@palette) -> @renderList() if @attached

  getColorsList: (palette) ->
    switch @sortPaletteColors
      when 'by color' then palette.sortedByColor()
      when 'by name' then palette.sortedByName()
      else palette.tuple()

  renderList: ->
    @stickyTitle?.dispose()
    @list.innerHTML = ''

    if @groupPaletteColors is 'by file'
      palettes = @getFilesPalettes()
      for file, palette of palettes
        li = document.createElement('li')
        li.className = 'pigments-color-group'
        ol = document.createElement('ol')

        li.appendChild @getGroupHeader(atom.project.relativize(file))
        li.appendChild ol
        @buildList(ol, @getColorsList(palette))
        @list.appendChild(li)

      @stickyTitle = new StickyTitle(
        @list.querySelectorAll('.pigments-color-group-header-content'),
        @querySelector('.pigments-palette-list')
      )
    else
      @buildList(@list, @getColorsList(@palette))

  getGroupHeader: (label) ->
    header = document.createElement('div')
    header.className = 'pigments-color-group-header'

    content = document.createElement('div')
    content.className = 'pigments-color-group-header-content'
    content.textContent = label

    header.appendChild(content)
    header

  getFilesPalettes: ->
    palettes = {}

    @palette.eachColor (name, color) =>
      variable = @project.getVariableByName(name)
      return unless variable?

      {path} = variable

      palettes[path] ?= new Palette
      palettes[path].colors[name] = color

    palettes

  buildList: (container, paletteColors) ->
    paletteColors = @checkForDuplicates(paletteColors)
    for [names, color] in paletteColors
      li = document.createElement('li')
      li.className = 'pigments-color-item'
      html = """
      <div class="pigments-color">
        <span class="pigments-color-preview"
              style="background-color: #{color.toCSS()}">
        </span>
        <span class="pigments-color-properties">
          <span class="pigments-color-component"><strong>R:</strong> #{Math.round color.red}</span>
          <span class="pigments-color-component"><strong>G:</strong> #{Math.round color.green}</span>
          <span class="pigments-color-component"><strong>B:</strong> #{Math.round color.blue}</span>
          <span class="pigments-color-component"><strong>A:</strong> #{Math.round(color.alpha * 1000) / 1000}</span>
        </span>
      </div>
      <div class="pigments-color-details">
      """

      for name in names
        html += """
        <span class="pigments-color-occurence">
            <span class="name">#{name}</span>
        """
        if variable = @project.getVariableByName(name)
          html += """
          <span data-variable-id="#{variable.id}">
            <span class="path">#{atom.project.relativize(variable.path)}</span>
            <span class="line">at line #{variable.line + 1}</span>
          </span>
          """

        html += '</span>'

      html += '</div>'

      li.innerHTML = html

      container.appendChild(li)

  checkForDuplicates: (paletteColors) ->
    results = []
    if @mergeColorDuplicates
      map = new Map()

      colors = []

      findColor = (color) ->
        return col for col in colors when col.isEqual(color)

      for [k,v] in paletteColors
        if key = findColor(v)
          map.get(key).push(k)
        else
          map.set(v, [k])
          colors.push(v)

      map.forEach (names, color) -> results.push [names, color]

      return results
    else
      return ([[name], color] for [name, color] in paletteColors)


module.exports = PaletteElement =
document.registerElement 'pigments-palette', {
  prototype: PaletteElement.prototype
}

PaletteElement.registerViewProvider = (modelClass) ->
  atom.views.addViewProvider modelClass, (model) ->
    element = new PaletteElement
    element.setModel(model)
    element
