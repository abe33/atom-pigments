[
  CompositeDisposable, variablesRegExp, _
] = []

module.exports =
class PigmentsProvider
  constructor: (@pigments) ->
    CompositeDisposable ?= require('atom').CompositeDisposable

    @subscriptions = new CompositeDisposable
    @selector = atom.config.get('pigments.autocompleteScopes').join(',')

    @subscriptions.add atom.config.observe 'pigments.autocompleteScopes', (scopes) =>
      @selector = scopes.join(',')
    @subscriptions.add atom.config.observe 'pigments.extendAutocompleteToVariables', (@extendAutocompleteToVariables) =>
    @subscriptions.add atom.config.observe 'pigments.extendAutocompleteToColorValue', (@extendAutocompleteToColorValue) =>

    @subscriptions.add atom.config.observe 'pigments.autocompleteSuggestionsFromValue', (@autocompleteSuggestionsFromValue) =>

  dispose: ->
    @disposed = true
    @subscriptions.dispose()
    @pigments = null

  getProject: ->
    return if @disposed
    @pigments.getProject()

  getSuggestions: ({editor, bufferPosition}) ->
    return if @disposed
    prefix = @getPrefix(editor, bufferPosition)
    project = @getProject()

    return unless prefix?.length
    return unless project?

    if @extendAutocompleteToVariables
      variables = project.getVariables()
    else
      variables = project.getColorVariables()

    suggestions = @findSuggestionsForPrefix(variables, prefix)
    suggestions

  getPrefix: (editor, bufferPosition) ->
    variablesRegExp ?= require('./regexes').variables
    line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition])

    if @autocompleteSuggestionsFromValue
      line.match(/(?:#[a-fA-F0-9]*|rgb.+)$/)?[0] ?
      line.match(new RegExp("(#{variablesRegExp})$"))?[0] ?
      line.match(/:\s*([^\s].+)$/)?[1] ?
      line.match(/^\s*([^\s].+)$/)?[1] ?
      ''
    else
      line.match(new RegExp("(#{variablesRegExp})$"))?[0] or ''

  findSuggestionsForPrefix: (variables, prefix) ->
    return [] unless variables?

    _ ?= require 'underscore-plus'

    re = ///^#{_.escapeRegExp(prefix).replace(/,\s*/, '\\s*,\\s*')}///

    suggestions = []
    matchesColorValue = (v) ->
      res = re.test(v.value)
      res ||= v.color.suggestionValues.some((s) -> re.test(s)) if v.color?
      res

    matchedVariables = variables.filter (v) =>
      not v.isAlternate and re.test(v.name) or
      (@autocompleteSuggestionsFromValue and matchesColorValue(v))

    matchedVariables.forEach (v) =>
      if v.isColor
        color = if v.color.alpha == 1 then '#' + v.color.hex else v.color.toCSS();
        rightLabelHTML = "<span class='color-suggestion-preview' style='background: #{v.color.toCSS()}'></span>"
        rightLabelHTML = "#{color} #{rightLabelHTML}" if @extendAutocompleteToColorValue

        suggestions.push {
          text: v.name
          rightLabelHTML
          replacementPrefix: prefix
          className: 'color-suggestion'
        }
      else
        suggestions.push {
          text: v.name
          rightLabel: v.value
          replacementPrefix: prefix
          className: 'pigments-suggestion'
        }

    suggestions
