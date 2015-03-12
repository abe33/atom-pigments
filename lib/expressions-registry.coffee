ColorExpression = require './color-expression'

module.exports =
class ExpressionsRegistry
  # The {Object} where color expression handlers are stored
  constructor: (@expressionsType) ->
    @colorExpressions = {}

  getExpressions: ->
    (e for k,e of @colorExpressions).sort((a,b) -> b.priority - a.priority)

  getExpression: (name) -> @colorExpressions[name]

  createExpression: (name, regexpString, priority=0, handle) ->
    [priority, handle] = [0, priority] if typeof priority is 'function'
    newExpression = new @expressionsType({name, regexpString, handle})
    newExpression.priority = priority
    @addExpression newExpression

  addExpression: (expression) ->
    @colorExpressions[expression.name] = expression

  removeExpression: (name) -> delete @colorExpressions[name]

  registerServiceConsumer: ->
    serviceName = @getServiceName()

    @consumerSubscription = atom.packages.serviceHub.consume(
      serviceName, '>=0.1.0', (provider) =>
        registerProvider = (o) =>
          {name, regexp, handler} = o
          @createExpression(name, regexp, handler)

        if Array.isArray(provider)
          registerProvider(p) for p in provider
        else
          registerProvider(provider)
    )

  disposeServiceConsumer: ->
    @consumerSubscription?.dispose()
    @consumerSubscription = null

  getServiceName: ->
    serviceName = @expressionsType.name.
    replace(/([a-z])([A-Z])/g, "$1-$2")
    .split(/-+/g)
    .join('-')
    .toLowerCase()

    "pigments.#{serviceName}-provider"
