module.exports =
class VariableExpression
  constructor: ({@name, @regexpString, @handle}) ->
    @regexp = new RegExp("^#{@regexpString}$")

  match: (expression) -> @regexp.test expression

  parse: (expression) ->
    results = undefined
    # match = re.exec(string)
    #
    # if match?
    #   if block?
    #     block(m, startIndex, lastIndex, solver)
    #   else
    #     [_, key, value] = m
    #     solver.appendResult([key, value, startIndex, lastIndex])
    #     return lastIndex

    results
