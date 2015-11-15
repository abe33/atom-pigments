{countLines} = require './utils'
{getRegistry} = require './color-expressions'
ColorParser = require './color-parser'

module.exports =
class ColorScanner
  constructor: ({@context}={}) ->
    @parser = @context.parser
    @registry = @context.registry

  getRegExp: ->
    @regexp = new RegExp(@registry.getRegExp(), 'g')

  getRegExpForScope: (scope) ->
    @regexp = new RegExp(@registry.getRegExpForScope(scope), 'g')

  search: (text, scope, start=0) ->
    @regexp = @getRegExpForScope(scope)
    @regexp.lastIndex = start

    if match = @regexp.exec(text)
      [matchText] = match
      {lastIndex} = @regexp

      color = @parser.parse(matchText, scope)

      if (index = matchText.indexOf(color.colorExpression)) > 0
        lastIndex += -matchText.length + index + color.colorExpression.length
        matchText = color.colorExpression

      color: color
      match: matchText
      lastIndex: lastIndex
      range: [
        lastIndex - matchText.length
        lastIndex
      ]
      line: countLines(text[0..lastIndex - matchText.length]) - 1
