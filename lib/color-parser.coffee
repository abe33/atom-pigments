
Color = require './color'
ColorExpression = require './color-expression'
ColorContext = require './color-context'

module.exports =
class ColorParser
  constructor: (@registry, @context) ->

  parse: (expression) ->
    return undefined if not expression? or expression is ''

    for e in @registry.getExpressions()
      if e.match(expression)
        res = e.parse(expression, @context)
        res.variables = @context.readUsedVariables()
        return res

    return undefined
