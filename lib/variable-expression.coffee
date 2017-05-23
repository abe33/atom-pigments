module.exports =
class VariableExpression
  @DEFAULT_HANDLE: (match, solver) ->
    [_, name, value] = match
    start = _.indexOf(name)
    end = _.indexOf(value) + value.length
    solver.appendResult(name, value, start, end)
    solver.endParsing(end)

  constructor: ({@name, @regexpString, @scopes, @priority, @handle}) ->
    @regexp = new RegExp("#{@regexpString}", 'm')
    @handle ?= @constructor.DEFAULT_HANDLE

  match: (expression) -> @regexp.test expression

  parse: (expression) ->
    parsingAborted = false
    results = []

    match = @regexp.exec(expression)
    if match?

      [matchText] = match
      {lastIndex} = @regexp
      startIndex = lastIndex - matchText.length

      solver =
        endParsing: (end) ->
          start = expression.indexOf(matchText)
          results.lastIndex = end
          results.range = [start,end]
          results.match = matchText[start...end]
        abortParsing: ->
          parsingAborted = true
        appendResult: (name, value, start, end, {isAlternate, noNamePrefix, isDefault}={}) ->
          range = [start, end]
          reName = name.replace(/([()$])/g, '\\$1')
          unless ///#{reName}(?![-_])///.test(value)
            results.push {
              name, value, range, isAlternate, noNamePrefix
              default: isDefault
            }

      @handle(match, solver)

    if parsingAborted then undefined else results
