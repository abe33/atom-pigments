{Emitter} = require 'event-kit'
ColorExpression = require './color-expression'
vm = require 'vm'

module.exports =
class ExpressionsRegistry
  @deserialize: (serializedData, expressionsType) ->
    registry = new ExpressionsRegistry(expressionsType)

    for name, data of serializedData.expressions
      handle = vm.runInNewContext(data.handle.replace('function', "handle = function"), {console, require})
      registry.createExpression(name, data.regexpString, data.priority, data.scopes, handle)

    registry.regexpStrings['none'] = serializedData.regexpString

    registry

  # The {Object} where color expression handlers are stored
  constructor: (@expressionsType) ->
    @colorExpressions = {}
    @emitter = new Emitter
    @regexpStrings = {}

  dispose: ->
    @emitter.dispose()

  onDidAddExpression: (callback) ->
    @emitter.on 'did-add-expression', callback

  onDidRemoveExpression: (callback) ->
    @emitter.on 'did-remove-expression', callback

  onDidUpdateExpressions: (callback) ->
    @emitter.on 'did-update-expressions', callback

  getExpressions: ->
    (e for k,e of @colorExpressions).sort((a,b) -> b.priority - a.priority)

  getExpressionsForScope: (scope) ->
    expressions = @getExpressions()

    return expressions if scope is '*'

    expressions.filter (e) -> '*' in e.scopes or scope in e.scopes

  getExpression: (name) -> @colorExpressions[name]

  getRegExp: ->
    @regexpStrings['none'] ?= @getExpressions().map((e) ->
      "(#{e.regexpString})").join('|')

  getRegExpForScope: (scope) ->
    @regexpStrings[scope] ?= @getExpressionsForScope(scope).map((e) ->
      "(#{e.regexpString})").join('|')

  createExpression: (name, regexpString, priority=0, scopes=['*'], handle) ->
    if typeof priority is 'function'
      handle = priority
      scopes = ['*']
      priority = 0
    else if typeof priority is 'object'
      handle = scopes if typeof scopes is 'function'
      scopes = priority
      priority = 0

    scopes.push('pigments') unless scopes.length is 1 and scopes[0] is '*'

    newExpression = new @expressionsType({name, regexpString, scopes, priority, handle})
    @addExpression newExpression

  addExpression: (expression, batch=false) ->
    @regexpStrings = {}
    @colorExpressions[expression.name] = expression

    unless batch
      @emitter.emit 'did-add-expression', {name: expression.name, registry: this}
      @emitter.emit 'did-update-expressions', {name: expression.name, registry: this}
    expression

  createExpressions: (expressions) ->
    @addExpressions expressions.map (e) =>
      {name, regexpString, handle, priority, scopes} = e
      priority ?= 0
      expression = new @expressionsType({name, regexpString, scopes, handle})
      expression.priority = priority
      expression

  addExpressions: (expressions) ->
    for expression in expressions
      @addExpression(expression, true)
      @emitter.emit 'did-add-expression', {name: expression.name, registry: this}
    @emitter.emit 'did-update-expressions', {registry: this}

  removeExpression: (name) ->
    delete @colorExpressions[name]
    @regexpStrings = {}
    @emitter.emit 'did-remove-expression', {name, registry: this}
    @emitter.emit 'did-update-expressions', {name, registry: this}

  serialize: ->
    out =
      regexpString: @getRegExp()
      expressions: {}

    for key, expression of @colorExpressions
      out.expressions[key] =
        name: expression.name
        regexpString: expression.regexpString
        priority: expression.priority
        scopes: expression.scopes
        handle: expression.handle?.toString()

    out
