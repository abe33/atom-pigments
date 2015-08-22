{CompositeDisposable} = require 'atom'
{SpacePenDSL, EventsDelegation} = require 'atom-utils'

class ColorProjectElement extends HTMLElement
  SpacePenDSL.includeInto(this)
  EventsDelegation.includeInto(this)

  @content: ->
    projectField = (name, label) =>
      settingName = "pigments.#{name}"
      schema = atom.config.getSchema(settingName)

      @div class: 'control-group', =>
        @div class: 'controls', =>
          @label class: 'control-label', =>
            @span class: 'setting-title', label

          @div class: 'control-wrapper', =>
            @tag 'atom-text-editor', mini: true, outlet: "#{name}Project", type: 'array', property: name
            @div class: 'setting-description', "Global value: #{atom.config.get(settingName).join(', ')}"

    @section class: 'settings-view pane-item', =>
      @div class: 'settings-wrapper', =>
        @div class: 'logo', =>
          @img src: 'atom://pigments/resources/logo.svg', width: 320, height: 80

        @div class: 'fields', =>
          projectField('sourceNames', 'Source Names')
          projectField('ignoredNames', 'Ignored Names')
          projectField('ignoredScopes', 'Ignored Scopes')

  createdCallback: ->

  setModel: (@project) ->
    @initializeTextEditors()

  initializeTextEditors: ->
    grammar = atom.grammars.grammarForScopeName('source.js.regexp')

    @sourceNamesProject.getModel().setText((@project.sourceNames ? []).join(', '))
    @ignoredNamesProject.getModel().setText((@project.ignoredNames ? []).join(', '))
    @ignoredScopesProject.getModel().setText((@project.ignoredScopes ? []).join(', '))

    @ignoredScopesProject.getModel().setGrammar(grammar)

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
