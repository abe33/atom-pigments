
registry = require './variable-expressions'

module.exports =
class VariableParser
  parse: (expression) ->
    for e in registry.getExpressions()
      return e.parse(expression) if e.match(expression)

    return
