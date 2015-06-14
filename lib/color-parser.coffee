
Color = require './color'
ColorExpression = require './color-expression'
ColorContext = null

{getRegistry} = require './color-expressions'

module.exports =
class ColorParser
  constructor: ->

  parse: (expression, context) ->
    unless context?
      ColorContext ?= require './color-context'
      context = new ColorContext
    context.parser ?= this

    return undefined if not expression? or expression is ''

    registry = getRegistry(context)

    for e in registry.getExpressions()
      if e.match(expression)
        res = e.parse(expression, context)
        res.variables = context.readUsedVariables()
        return res

    return undefined
