module.exports =
class VariableExpression
  @DEFAULT_HANDLE: (match, solver) ->
    [_, name, value] = match
    start = _.indexOf(name)
    end = _.indexOf(value) + value.length
    solver.appendResult([name, value, start, end])
    solver.endParsing(end)

  constructor: ({@name, @regexpString, @handle}) ->
    @regexp = new RegExp("#{@regexpString}", 'm')
    @handle ?= @constructor.DEFAULT_HANDLE

  match: (expression) -> @regexp.test expression

  parse: (expression) ->
    results = []

    match = @regexp.exec(expression)
    if match?

      [matchText] = match
      {lastIndex} = @regexp
      startIndex = lastIndex - matchText.length

      solver =
        endParsing: (index) ->
          results.lastIndex = index
          results.range = [0,index]
        appendResult: ([name, value, start, end]) ->
          range = [start, end]
          results.push {name, value, range}

      @handle(match, solver)

    results
