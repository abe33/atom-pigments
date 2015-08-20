_ = require 'underscore-plus'
{CompositeDisposable, Range}  = require 'atom'
{variables: variablesRegExp} = require './regexes'

module.exports =
class PigmentsProvider
  constructor: (@pigments) ->
    @subscriptions = new CompositeDisposable
    @selector = atom.config.get('pigments.autocompleteScopes').join(',')

    @subscriptions.add atom.config.observe 'pigments.autocompleteScopes', (scopes) =>
      @selector = scopes.join(',')
    @subscriptions.add atom.config.observe 'pigments.extendAutocompleteToVariables', (@extendAutocompleteToVariables) =>

  dispose: ->
    @subscriptions.dispose()
    @pigments = null

  getProject: -> @pigments.getProject()

  getSuggestions: ({editor, bufferPosition}) ->
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
    line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition])

    line.match(new RegExp(variablesRegExp + '$'))?[0] or ''

  findSuggestionsForPrefix: (variables, prefix) ->
    return [] unless variables?

    suggestions = []

    matchedVariables = variables.filter (v) -> ///^#{_.escapeRegExp prefix}///.test v.name

    matchedVariables.forEach (v) ->
      if v.isColor
        suggestions.push {
          text: v.name
          rightLabelHTML: "<span class='color-suggestion-preview' style='background: #{v.color.toCSS()}'></span>"
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
