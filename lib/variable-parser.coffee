
module.exports =
class VariableParser
  constructor: (@registry) ->
  parse: (expression) ->
    for e in @registry.getExpressions()
      return e.parse(expression) if e.match(expression)

    return
