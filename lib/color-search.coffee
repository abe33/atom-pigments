{Emitter} = require 'atom'
{Minimatch} = require 'minimatch'
{getRegistry} = require './color-expressions'
ColorParser = require './color-parser'
ColorContext = require './color-context'

module.exports =
class ColorSearch
  constructor: (options={}) ->
    {@sourceNames, ignoredNames, @context} = options
    @emitter = new Emitter
    @parser = new ColorParser
    @context ?= new ColorContext([])
    @variables = @context.getVariables()
    @sourceNames ?= []
    @context.parser = @parser
    ignoredNames ?= []

    @ignoredNames = []
    for ignore in ignoredNames when ignore?
      try
        @ignoredNames.push(new Minimatch(ignore, matchBase: true, dot: true))
      catch error
        console.warn "Error parsing ignore pattern (#{ignore}): #{error.message}"


  onDidCompleteSearch: (callback) ->
    @emitter.on 'did-complete-search', callback

  search: ->
    registry = getRegistry(@context)

    re = new RegExp registry.getRegExp()
    results = []

    promise = atom.workspace.scan re, paths: @sourceNames, (m) =>
      relativePath = atom.project.relativize(m.filePath)
      return if @isIgnored(relativePath)

      for result in m.matches
        result.color = @parser.parse(result.matchText, @context)
        result.range[0][1] += result.matchText.indexOf(result.color.colorExpression)
        result.matchText = result.color.colorExpression

        results.push result

    promise.then =>
      @emitter.emit 'did-complete-search', results

  isIgnored: (relativePath) ->
    for ignoredName in @ignoredNames
      return true if ignoredName.match(relativePath)
