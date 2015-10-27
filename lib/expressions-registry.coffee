ColorExpression = require './color-expression'
vm = require 'vm'

module.exports =
class ExpressionsRegistry
  @deserialize: (serializedData, expressionsType) ->
    registry = new ExpressionsRegistry(expressionsType)

    for name, data of serializedData.expressions
      handle = vm.runInNewContext("handle = " + data.handle)
      registry.createExpression(name, data.regexpString, handle)

    registry.regexpString = serializedData.regexpString

    registry

  # The {Object} where color expression handlers are stored
  constructor: (@expressionsType) ->
    @colorExpressions = {}

  getExpressions: ->
    (e for k,e of @colorExpressions).sort((a,b) -> b.priority - a.priority)

  getExpression: (name) -> @colorExpressions[name]

  getRegExp: ->
    @regexpString ?= @getExpressions().map((e) -> "(#{e.regexpString})").join('|')

  createExpression: (name, regexpString, priority=0, handle) ->
    [priority, handle] = [0, priority] if typeof priority is 'function'
    newExpression = new @expressionsType({name, regexpString, handle})
    newExpression.priority = priority
    @addExpression newExpression

  addExpression: (expression) ->
    delete @regexpString
    @colorExpressions[expression.name] = expression

  removeExpression: (name) ->
    delete @regexpString
    delete @colorExpressions[name]

  serialize: ->
    out =
      regexpString: @getRegExp()
      expressions: {}

    for key, expression of @colorExpressions
      out.expressions[key] =
        name: expression.name
        regexpString: expression.regexpString
        handle: expression.handle?.toString()

    out
