[registry, regexpString, regexp] = []
ColorParser = require './color-parser'

module.exports =
class ColorScanner
  constructor: (params={}) ->
    {@parser, @context} = params
    @parser ?= new ColorParser

  getRegExp: ->
    registry ?= require './color-expressions'
    regexpString ?= registry.getRegExp()

    regexp ?= new RegExp(regexpString, 'g')

  search: (text, start=0) ->
    regexp = @getRegExp()
    regexp.lastIndex = start

    if match = regexp.exec(text)
      [matchText] = match
      {lastIndex} = regexp

      color = @parser.parse(matchText, @context)
      color.variables = @context.readUsedVariables() if @context?

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
