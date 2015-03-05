[registry, regexpString] = []

module.exports =
class ColorScanner
  constructor: ({@buffer}) ->

  getRegExp: ->
    registry ?= require './expressions'
    regexpString ?= registry.getExpressions()
    .map (e) -> "(#{e.regexpString})"
    .join('|')

    new RegExp(regexpString, 'g')

  search: (start=0) ->
    text = @buffer.getText()
    regexp = @getRegExp()
    regexp.lastIndex = start

    if match = regexp.exec(text)
      [matchText] = match
      {lastIndex} = regexp

      match: matchText
      range: [lastIndex - matchText.length, lastIndex]
