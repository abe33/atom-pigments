[Emitter, Minimatch, ColorContext, registry] = []

module.exports =
class ColorSearch
  @deserialize: (state) -> new ColorSearch(state.options)

  constructor: (@options={}) ->
    {@sourceNames, ignoredNames: @ignoredNameSources, @context, @project} = @options
    {Emitter} = require 'atom' unless Emitter?
    @emitter = new Emitter

    if @project?
      @init()
    else
      subscription = atom.packages.onDidActivatePackage (pkg) =>
        if pkg.name is 'pigments'
          subscription.dispose()
          @project = pkg.mainModule.getProject()
          @init()

  init: ->
    {Minimatch} = require 'minimatch' unless Minimatch?
    ColorContext ?= require './color-context'

    @context ?= new ColorContext(registry: @project.getColorExpressionsRegistry())

    @parser = @context.parser
    @variables = @context.getVariables()
    @sourceNames ?= []
    @ignoredNameSources ?= []

    @ignoredNames = []
    for ignore in @ignoredNameSources when ignore?
      try
        @ignoredNames.push(new Minimatch(ignore, matchBase: true, dot: true))
      catch error
        console.warn "Error parsing ignore pattern (#{ignore}): #{error.message}"

    @search() if @searchRequested

  getTitle: -> 'Pigments Find Results'

  getURI: -> 'pigments://search'

  getIconName: -> "pigments"

  onDidFindMatches: (callback) ->
    @emitter.on 'did-find-matches', callback

  onDidCompleteSearch: (callback) ->
    @emitter.on 'did-complete-search', callback

  search: ->
    unless @project?
      @searchRequested = true
      return

    re = new RegExp @project.getColorExpressionsRegistry().getRegExp()
    results = []

    promise = atom.workspace.scan re, paths: @sourceNames, (m) =>
      relativePath = atom.project.relativize(m.filePath)
      scope = @project.scopeFromFileName(relativePath)
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
      options: {
        @sourceNames,
        ignoredNames: @ignoredNameSources
      }
    }
