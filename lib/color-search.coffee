{Emitter} = require 'atom'
{Minimatch} = require 'minimatch'
registry = require './color-expressions'
ColorParser = require './color-parser'
ColorContext = require './color-context'
scopeFromFileName = require './scope-from-file-name'

module.exports =
class ColorSearch
  @deserialize: (state) -> new ColorSearch(state.options)

  constructor: (@options={}) ->
    {@sourceNames, ignoredNames, @context} = @options
    @emitter = new Emitter
    @context ?= new ColorContext({registry})
    @parser = @context.parser
    @variables = @context.getVariables()
    @sourceNames ?= []
    ignoredNames ?= []

    @ignoredNames = []
    for ignore in ignoredNames when ignore?
      try
        @ignoredNames.push(new Minimatch(ignore, matchBase: true, dot: true))
      catch error
        console.warn "Error parsing ignore pattern (#{ignore}): #{error.message}"

  getTitle: -> 'Pigments Find Results'

  getURI: -> 'pigments://search'

  getIconName: -> "pigments"

  onDidFindMatches: (callback) ->
    @emitter.on 'did-find-matches', callback

  onDidCompleteSearch: (callback) ->
    @emitter.on 'did-complete-search', callback

  search: ->
    re = new RegExp registry.getRegExp()
    results = []

    promise = atom.workspace.scan re, paths: @sourceNames, (m) =>
      relativePath = atom.project.relativize(m.filePath)
      scope = scopeFromFileName(relativePath)
      return if @isIgnored(relativePath)

      newMatches = []
      for result in m.matches
        result.color = @parser.parse(result.matchText, scope)
        # FIXME it should be handled way before, but it'll need a change
        # in how we test if a variable is a color.
        continue unless result.color?.isValid()
        # FIXME Seems like, sometime the range of the result is undefined,
        # we'll ignore that for now and log the faulting result.
        unless result.range[0]?
          console.warn "Color search returned a result with an invalid range", result
          continue
        result.range[0][1] += result.matchText.indexOf(result.color.colorExpression)
        result.matchText = result.color.colorExpression

        results.push result
        newMatches.push result

      m.matches = newMatches

      @emitter.emit 'did-find-matches', m if m.matches.length > 0

    promise.then =>
      @results = results
      @emitter.emit 'did-complete-search', results

  isIgnored: (relativePath) ->
    for ignoredName in @ignoredNames
      return true if ignoredName.match(relativePath)

  serialize: ->
    {
      deserializer: 'ColorSearch'
      @options
    }
