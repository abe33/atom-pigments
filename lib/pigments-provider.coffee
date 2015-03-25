{CompositeDisposable, Range}  = require('atom')
fuzzaldrin = require('fuzzaldrin')

module.exports =
class PigmentsProvider
  constructor: (@project) ->
    @subscriptions = new CompositeDisposable
    @selector = atom.config.get('pigments.autocompleteScopes').join(',')

    @subscriptions.add atom.config.observe 'pigments.autocompleteScopes', (scopes) =>
      @selector = scopes.join(',')
    @subscriptions.add atom.config.observe 'pigments.extendAutocompleteToVariables', (@extendAutocompleteToVariables) =>

  dispose: ->
    @subscriptions.dispose()
    @project = null

  getSuggestions: ({scopeDescriptor, prefix}) ->
    return unless prefix?.length

    console.log 'in pigments provider'

    if @extendAutocompleteToVariables
      variables = @project.getVariables()
    else
      variables = @project.getColorVariables()

    suggestions = @findSuggestionsForPrefix(variables, prefix)
    console.log suggestions
    suggestions

  findSuggestionsForPrefix: (variables, prefix) ->
    return [] unless variables?

    suggestions = []

    allNames = variables.map (v) -> v.name
    matchedNames = fuzzaldrin.filter(allNames, prefix)
    matchedVariables = variables.filter (v) -> v.name in matchedNames

    matchedVariables.forEach (v) ->
      if v.isColor()
        suggestions.push {
          text: v.name
          rightLabelHTML: "<span class='color-suggestion-preview' style='background: #{v.getColor().toCSS()}'></span>"
          className: 'color-suggestion'
        }
      else
        suggestions.push {
          text: v.name
          rightLabel: v.value
          className: 'pigments-suggestion'
        }

    suggestions
