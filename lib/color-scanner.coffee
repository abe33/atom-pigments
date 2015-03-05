[registry, regexpString, regexp] = []
ColorParser = require './color-parser'

module.exports =
class ColorScanner
  constructor: (params) ->
    {@buffer, @parser} = params
    @parser ?= new ColorParser

  getRegExp: ->
    registry ?= require './expressions'
    regexpString ?= registry.getExpressions()
    .map (e) -> "(#{e.regexpString})"
    .join('|')

    regexp ?= new RegExp(regexpString, 'g')

  search: (start) ->
    text = @buffer.getText()
    regexp = @getRegExp()
    regexp.lastIndex = start ? @lastIndex

    if match = regexp.exec(text)
      [matchText] = match
      {@lastIndex} = regexp

      color = @parser.parse(matchText)

      if (index = matchText.indexOf(color.colorExpression)) > 0
        @lastIndex += -matchText.length + index + color.colorExpression.length
        matchText = color.colorExpression

      properties =
        color: color
        match: matchText
        textRange: [
          @lastIndex - matchText.length
          @lastIndex
        ]
        bufferRange: [
          @buffer.positionForCharacterIndex(@lastIndex - matchText.length)
          @buffer.positionForCharacterIndex(@lastIndex)
        ]
      console.log properties
      properties
