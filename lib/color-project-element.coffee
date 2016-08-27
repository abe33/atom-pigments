{SpacePenDSL, EventsDelegation, registerOrUpdateElement} = require 'atom-utils'
CompositeDisposable = null

capitalize = (s) -> s.replace /^./, (m) -> m.toUpperCase()

class ColorProjectElement extends HTMLElement
  SpacePenDSL.includeInto(this)
  EventsDelegation.includeInto(this)

  @content: ->
    arrayField = (name, label, setting, description) =>
      settingName = "pigments.#{name}"

      @div class: 'control-group array', =>
        @div class: 'controls', =>
          @label class: 'control-label', =>
            @span class: 'setting-title', label

          @div class: 'control-wrapper', =>
            @tag 'atom-text-editor', mini: true, outlet: name, type: 'array', property: name
            @div class: 'setting-description', =>
              @div =>
                @raw "Global config: <code>#{atom.config.get(setting ? settingName).join(', ')}</code>"

                @p(=> @raw description) if description?

              booleanField("ignoreGlobal#{capitalize name}", 'Ignore Global', null, true)

    selectField = (name, label, {options, setting, description, useBoolean}={}) =>
      settingName = "pigments.#{name}"

      @div class: 'control-group array', =>
        @div class: 'controls', =>
          @label class: 'control-label', =>
            @span class: 'setting-title', label

          @div class: 'control-wrapper', =>
            @select outlet: name, class: 'form-control', required: true, =>
              options.forEach (option) =>
                if option is ''
                  @option value: option, 'Use global config'
                else
                  @option value: option, capitalize option

            @div class: 'setting-description', =>
              @div =>
                @raw "Global config: <code>#{atom.config.get(setting ? settingName)}</code>"

                @p(=> @raw description) if description?

              if useBoolean
                booleanField("ignoreGlobal#{capitalize name}", 'Ignore Global', null, true)

    booleanField = (name, label, description, nested) =>
      @div class: 'control-group boolean', =>
        @div class: 'controls', =>
          @input type: 'checkbox', id: "pigments-#{name}", outlet: name
          @label class: 'control-label', for: "pigments-#{name}", =>
            @span class: (if nested then 'setting-description' else 'setting-title'), label

          if description?
            @div class: 'setting-description', =>
              @raw description

    @section class: 'settings-view pane-item', =>
      @div class: 'settings-wrapper', =>
        @div class: 'header', =>
          @div class: 'logo', =>
            @img src: 'atom://pigments/resources/logo.svg', width: 140, height: 35

          @p class: 'setting-description', """
          These settings apply on the current project only and are complementary
          to the package settings.
          """

        @div class: 'fields', =>
          themes = atom.themes.getActiveThemeNames()
          arrayField('sourceNames', 'Source Names')
          arrayField('ignoredNames', 'Ignored Names')
          arrayField('supportedFiletypes', 'Supported Filetypes')
          arrayField('ignoredScopes', 'Ignored Scopes')
          arrayField('searchNames', 'Extended Search Names', 'pigments.extendedSearchNames')
          selectField('sassShadeAndTintImplementation', 'Sass Shade And Tint Implementation', {
            options: ['', 'compass', 'bourbon']
            setting: 'pigments.sassShadeAndTintImplementation'
            description: "Sass doesn't provide any implementation for shade and tint function, and Compass and Bourbon have different implementation for these two methods. This setting allow you to chose which implementation use."
          })

          booleanField('includeThemes', 'Include Atom Themes Stylesheets', """
          The variables from <code>#{themes[0]}</code> and
          <code>#{themes[1]}</code> themes will be automatically added to the
          project palette.
          """)

  createdCallback: ->
    {CompositeDisposable} = require 'atom' unless CompositeDisposable?

    @subscriptions = new CompositeDisposable

  setModel: (@project) ->
    @initializeBindings()

  initializeBindings: ->
    grammar = atom.grammars.grammarForScopeName('source.js.regexp')
    @ignoredScopes.getModel().setGrammar(grammar)

    @initializeTextEditor('sourceNames')
    @initializeTextEditor('searchNames')
    @initializeTextEditor('ignoredNames')
    @initializeTextEditor('ignoredScopes')
    @initializeTextEditor('supportedFiletypes')
    @initializeCheckbox('includeThemes')
    @initializeCheckbox('ignoreGlobalSourceNames')
    @initializeCheckbox('ignoreGlobalIgnoredNames')
    @initializeCheckbox('ignoreGlobalIgnoredScopes')
    @initializeCheckbox('ignoreGlobalSearchNames')
    @initializeCheckbox('ignoreGlobalSupportedFiletypes')
    @initializeSelect('sassShadeAndTintImplementation')

  initializeTextEditor: (name) ->
    capitalizedName = capitalize name
    editor = @[name].getModel()

    editor.setText((@project[name] ? []).join(', '))

    @subscriptions.add editor.onDidStopChanging =>
      array = editor.getText().split(/\s*,\s*/g).filter (s) -> s.length > 0
      @project["set#{capitalizedName}"](array)

  initializeSelect: (name) ->
    capitalizedName = capitalize name
    select = @[name]
    optionValues = [].slice.call(select.querySelectorAll('option')).map (o) -> o.value

    if @project[name]
      select.selectedIndex = optionValues.indexOf(@project[name])

    @subscriptions.add @subscribeTo select, change: =>
      value = select.selectedOptions[0]?.value
      @project["set#{capitalizedName}"](if value is '' then null else value)

  initializeCheckbox: (name) ->
    capitalizedName = capitalize name
    checkbox = @[name]
    checkbox.checked = @project[name]

    @subscriptions.add @subscribeTo checkbox, change: =>
      @project["set#{capitalizedName}"](checkbox.checked)

  getTitle: -> 'Project Settings'

  getURI: -> 'pigments://settings'

  getIconName: -> "pigments"

  serialize: -> {deserializer: 'ColorProjectElement'}

module.exports =
ColorProjectElement =
registerOrUpdateElement 'pigments-color-project', ColorProjectElement.prototype
