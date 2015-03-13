[registry, regexpString, regexp] = []
VariableParser = require './variable-parser'

module.exports =
class VariableScanner
  constructor: (params={}) ->
    {@parser} = params
    @parser ?= new VariableParser

  getRegExp: ->
    registry ?= require './variable-expressions'
    regexpString ?= registry.getExpressions()
    .map (e) -> "(#{e.regexpString})"
    .join('|')

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
        for v in result
          v.range[0] += index
          v.range[1] += index

      result
