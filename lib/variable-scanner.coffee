{countLines} = require './utils'
VariableParser = require './variable-parser'
[registry, regexpString, regexp] = []

module.exports =
class VariableScanner
  constructor: (params={}) ->
    {@parser} = params
    @parser ?= new VariableParser

  getRegExp: ->
    registry ?= require './variable-expressions'
    regexpString ?= registry.getRegExp()

    regexp ?= new RegExp(regexpString, 'gm')

  search: (text, start=0) ->
    regexp = @getRegExp()
    regexp.lastIndex = start

    if match = regexp.exec(text)
      [matchText] = match
      {index} = match
      {lastIndex} = regexp

      result = @parser.parse(matchText)

      if result?
        result.lastIndex += index
        result.range[0] += index
        result.range[1] += index

        line = -1
        lineCountIndex = 0

        for v in result
          v.range[0] += index
          v.range[1] += index
          line = v.line = line + countLines(text[lineCountIndex..v.range[0]])
          lineCountIndex = v.range[0]

      result
