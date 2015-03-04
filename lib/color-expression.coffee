Color = require './color'

module.exports =
class ColorExpression
  constructor: (@name, @regexpString, @handle, @priority=0) ->
    @regexp = new RegExp("^#{@regexpString}$", 'i')

  match: (expression) -> @regexp.test expression

  parse: (expression) ->
    return null unless @match(expression)

    color = new Color()
    @handle.call(color, @regexp.exec(expression), expression, {})
    color

  search: (text, start=0) ->
    results = undefined
    re = new RegExp(@regexpString, 'gi')
    re.lastIndex = start
    if [match] = re.exec(text)
      {lastIndex} = re
      range = [lastIndex - match.length, lastIndex]
      results =
        range: range
        match: text[range[0]...range[1]]

    results
