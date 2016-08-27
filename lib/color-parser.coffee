
module.exports =
class ColorParser
  constructor: (@registry, @context) ->

  parse: (expression, scope='*', collectVariables=true) ->
    return undefined if not expression? or expression is ''

    for e in @registry.getExpressionsForScope(scope)
      if e.match(expression)
        res = e.parse(expression, @context)
        res.variables = @context.readUsedVariables() if collectVariables
        return res

    return undefined
