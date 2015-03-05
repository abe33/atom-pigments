
Color = require './color'
ColorExpression = require './color-expression'
ColorContext = require './color-context'

registry = require './expressions'

module.exports =
class ColorParser
  constructor: ->

  parse: (expression, context) ->
    context ?= new ColorContext(this)

    for e in registry.getExpressions()
      return e.parse(expression, context) if e.match(expression)

    return
