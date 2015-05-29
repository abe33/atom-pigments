{countLines} = require './utils'
{getRegistry} = require './color-expressions'
ColorParser = require './color-parser'

module.exports =
class ColorScanner
  constructor: (params={}) ->
    {@parser, @context} = params
    @parser ?= new ColorParser

  getRegExp: ->
    registry = getRegistry(@context)

    @regexp = new RegExp(registry.getRegExp(), 'g')

  search: (text, start=0) ->
    @regexp = @getRegExp()
    @regexp.lastIndex = start

    if match = @regexp.exec(text)
      [matchText] = match
      {lastIndex} = @regexp

      color = @parser.parse(matchText, @context)

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
