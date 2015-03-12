
describe 'color expressions service', ->
  [initialConsumersCount, initialCount, registry] = []

  beforeEach ->
    initialConsumersCount = atom.packages.serviceHub.consumers.length

    registry = require '../lib/expressions'
    registry.registerServiceConsumer()

    initialCount = registry.getExpressions().length

    expect(atom.packages.serviceHub.consumers.length).toEqual(initialConsumersCount + 1)

  afterEach ->
    registry.disposeServiceConsumer()

  describe 'with a service providing a single expression', ->
    beforeEach ->
      expressionObject =
        name: 'service-test-expression'
        regexp: 'dummy-expression'
        handler: (match, expression, context) ->

      atom.packages.serviceHub.provide(
        'pigments.color-expression-provider',
        '0.1.0',
        expressionObject
      )

    afterEach ->
      registry.removeExpression('service-test-expression')

    it 'registers the provided expression in the registry', ->
      expect(registry.getExpressions().length).toEqual(initialCount + 1)

  describe 'with a service providing an array of expressions', ->
    beforeEach ->
      expressionObject1 =
        name: 'service-test-expression-1'
        regexp: 'dummy-expression-1'
        handler: (match, expression, context) ->

      expressionObject2 =
        name: 'service-test-expression-2'
        regexp: 'dummy-expression-2'
        handler: (match, expression, context) ->

      atom.packages.serviceHub.provide(
        'pigments.color-expression-provider',
        '0.1.0',
        [expressionObject1, expressionObject2]
      )

    afterEach ->
      registry.removeExpression('service-test-expression-1')
      registry.removeExpression('service-test-expression-2')

    it 'registers the provided expression in the registry', ->
      expect(registry.getExpressions().length).toEqual(initialCount + 2)

  describe 'when disposed', ->
    beforeEach ->
      registry.disposeServiceConsumer()

    it 'removes the service consumer from the hub', ->
      expect(atom.packages.serviceHub.consumers.length).toEqual(initialConsumersCount)


describe 'variable expressions service', ->
  [initialConsumersCount, initialCount, registry] = []

  beforeEach ->
    initialConsumersCount = atom.packages.serviceHub.consumers.length

    registry = require '../lib/variables-expressions'
    registry.registerServiceConsumer()

    initialCount = registry.getExpressions().length

    expect(atom.packages.serviceHub.consumers.length).toEqual(initialConsumersCount + 1)

  afterEach ->
    registry.disposeServiceConsumer()

  describe 'with a service providing a single expression', ->
    beforeEach ->
      expressionObject =
        name: 'service-test-expression'
        regexp: 'dummy-expression'
        handler: (match, expression, context) ->

      atom.packages.serviceHub.provide(
        'pigments.variable-expression-provider',
        '0.1.0',
        expressionObject
      )

    afterEach ->
      registry.removeExpression('service-test-expression')

    it 'registers the provided expression in the registry', ->
      expect(registry.getExpressions().length).toEqual(initialCount + 1)

  describe 'with a service providing an array of expressions', ->
    beforeEach ->
      expressionObject1 =
        name: 'service-test-expression-1'
        regexp: 'dummy-expression-1'
        handler: (match, expression, context) ->

      expressionObject2 =
        name: 'service-test-expression-2'
        regexp: 'dummy-expression-2'
        handler: (match, expression, context) ->

      atom.packages.serviceHub.provide(
        'pigments.variable-expression-provider',
        '0.1.0',
        [expressionObject1, expressionObject2]
      )

    afterEach ->
      registry.removeExpression('service-test-expression-1')
      registry.removeExpression('service-test-expression-2')

    it 'registers the provided expression in the registry', ->
      expect(registry.getExpressions().length).toEqual(initialCount + 2)

  describe 'when disposed', ->
    beforeEach ->
      registry.disposeServiceConsumer()

    it 'removes the service consumer from the hub', ->
      expect(atom.packages.serviceHub.consumers.length).toEqual(initialConsumersCount)
