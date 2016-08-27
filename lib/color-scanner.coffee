countLines = null

module.exports =
class ColorScanner
  constructor: ({@context}={}) ->
    @parser = @context.parser
    @registry = @context.registry

  getRegExp: ->
    new RegExp(@registry.getRegExp(), 'g')

  getRegExpForScope: (scope) ->
    new RegExp(@registry.getRegExpForScope(scope), 'g')

  search: (text, scope, start=0) ->
    {countLines} = require './utils' unless countLines?

    regexp = @getRegExpForScope(scope)
    regexp.lastIndex = start

    if match = regexp.exec(text)
      [matchText] = match
      {lastIndex} = regexp

      color = @parser.parse(matchText, scope)

      # return unless color?

      if (index = matchText.indexOf(color.colorExpression)) > 0
        lastIndex += -matchText.length + index + color.colorExpression.length
        matchText = color.colorExpression

      color: color
      match: matchText
      lastIndex: lastIndex
      range: [
        lastIndex - matchText.length
        lastIndex
      ]
      line: countLines(text[0..lastIndex - matchText.length]) - 1
