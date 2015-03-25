ColorExpression = require './color-expression'

module.exports =
class ExpressionsRegistry
  # The {Object} where color expression handlers are stored
  constructor: (@expressionsType) ->
    @colorExpressions = {}

  getExpressions: ->
    (e for k,e of @colorExpressions).sort((a,b) -> b.priority - a.priority)

  getExpression: (name) -> @colorExpressions[name]

  getRegExp: ->
    @getExpressions().map((e) -> "(#{e.regexpString})").join('|')

  createExpression: (name, regexpString, priority=0, handle) ->
    [priority, handle] = [0, priority] if typeof priority is 'function'
    newExpression = new @expressionsType({name, regexpString, handle})
    newExpression.priority = priority
    @addExpression newExpression

  addExpression: (expression) ->
    @colorExpressions[expression.name] = expression

  removeExpression: (name) -> delete @colorExpressions[name]
