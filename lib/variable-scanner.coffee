{countLines} = require './utils'
VariableParser = require './variable-parser'

module.exports =
class VariableScanner
  constructor: (params={}) ->
    {@parser, @registry} = params
    @parser ?= new VariableParser(@registry)

  getRegExp: ->
    @regexp ?= new RegExp(@registry.getRegExp(), 'gm')

  search: (text, start=0) ->
    regexp = @getRegExp()
    regexp.lastIndex = start

    while match = regexp.exec(text)
      [matchText] = match
      {index} = match
      {lastIndex} = regexp

      result = @parser.parse(matchText)

      if result?
        result.lastIndex += index

        if result.length > 0
          result.range[0] += index
          result.range[1] += index

          line = -1
          lineCountIndex = 0

          for v in result
            v.range[0] += index
            v.range[1] += index
            line = v.line = line + countLines(text[lineCountIndex..v.range[0]])
            lineCountIndex = v.range[0]

          return result
        else
          regexp.lastIndex = result.lastIndex

    return undefined
