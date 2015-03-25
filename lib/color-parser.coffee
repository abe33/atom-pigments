
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

    registry = getRegistry(context)

    for e in registry.getExpressions()
      return e.parse(expression, context) if e.match(expression)

    return
