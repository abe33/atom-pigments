{CompositeDisposable} = require 'atom'
{SpacePenDSL, EventsDelegation} = require 'atom-utils'

class ColorProjectElement extends HTMLElement
  SpacePenDSL.includeInto(this)
  EventsDelegation.includeInto(this)

  @content: ->
    combinedField = (name, label) =>
      settingName = "pigments.#{name}"
      schema = atom.config.getSchema(settingName)

      @div class: 'control-group', =>
        @div class: 'controls', =>
          @label class: 'control-label', =>
            @span class: 'setting-title', label

          @div class: 'control-wrapper', =>
            @tag 'atom-text-editor', mini: true, outlet: "#{name}Project", type: 'array', property: name

          @div class: 'control-wrapper', =>
            @tag 'atom-text-editor', mini: true, outlet: "#{name}Setting", type: 'array', setting: settingName

    @section class: 'settings-view pane-item', =>
      @div class: 'settings-wrapper', =>
        @div class: 'logo', =>
          @img src: 'atom://pigments/resources/logo.svg', width: 320, height: 80

        @div class: 'fields', =>
          @div class: 'fields-header', =>
            @label class: 'control-label'

            @div class: 'control-wrapper', =>
              @h5 'Project settings'

            @div class: 'control-wrapper', =>
              @h5 'Global settings'

          combinedField('sourceNames', 'Source Names')
          combinedField('ignoredNames', 'Ignored Names')
          combinedField('ignoredScopes', 'Ignored Scopes')


  createdCallback: ->

  setModel: (@project) ->
    @initializeTextEditors()

  initializeTextEditors: ->
    grammar = atom.grammars.grammarForScopeName('source.js.regexp')

    @sourceNamesProject.getModel().setText((@project.sourceNames ? []).join(', '))
    @ignoredNamesProject.getModel().setText((@project.ignoredNames ? []).join(', '))
    @ignoredScopesProject.getModel().setText((@project.ignoredScopes ? []).join(', '))

    @sourceNamesSetting.getModel().setText(atom.config.get('pigments.sourceNames').join(', '))
    @ignoredNamesSetting.getModel().setText(atom.config.get('pigments.ignoredNames').join(', '))
    @ignoredScopesSetting.getModel().setText(atom.config.get('pigments.ignoredScopes').join(', '))

    @ignoredScopesProject.getModel().setGrammar(grammar)
    @ignoredScopesSetting.getModel().setGrammar(grammar)

  getTitle: -> 'Pigments Settings'

  getURI: -> 'pigments://settings'

  getIconName: -> "pigments"

module.exports = ColorProjectElement =
document.registerElement 'pigments-color-project', {
  prototype: ColorProjectElement.prototype
}

ColorProjectElement.registerViewProvider = (modelClass) ->
  atom.views.addViewProvider modelClass, (model) ->
    element = new ColorProjectElement
    element.setModel(model)
    element
