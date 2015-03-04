
Color = require './color'
ColorExpression = require './color-expression'

registry = require './expressions'

module.exports =
class ColorParser
  constructor: ->

  parse: (expression) ->
    for e in registry.getExpressions()
      return e.parse(expression) if e.match(expression)

    return
