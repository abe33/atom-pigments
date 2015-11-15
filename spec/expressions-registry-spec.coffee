ExpressionsRegistry = require '../lib/expressions-registry'

describe 'ExpressionsRegistry', ->
  [registry, Dummy] = []

  beforeEach ->
    class Dummy
      constructor: ({@name, @regexpString, @priority, @scopes, @handle}) ->

    registry = new ExpressionsRegistry(Dummy)

  describe '::createExpression', ->
    describe 'called with enough data', ->
      it 'creates a new expression of this registry expressions type', ->
        expression = registry.createExpression 'dummy', 'foo'

        expect(expression.constructor).toBe(Dummy)
        expect(registry.getExpressions()).toEqual([expression])

  describe '::addExpression', ->
    it 'adds a previously created expression in the registry', ->
      expression = new Dummy(name: 'bar')

      registry.addExpression(expression)

      expect(registry.getExpression('bar')).toBe(expression)
      expect(registry.getExpressions()).toEqual([expression])

  describe '::getExpressions', ->
    it 'returns the expression based on their priority', ->
      expression1 = registry.createExpression 'dummy1', '', 2
      expression2 = registry.createExpression 'dummy2', '', 0
      expression3 = registry.createExpression 'dummy3', '', 1

      expect(registry.getExpressions()).toEqual([
        expression1
        expression3
        expression2
      ])

  describe '::removeExpression', ->
    it 'removes an expression with its name', ->
      registry.createExpression 'dummy', 'foo'

      registry.removeExpression('dummy')

      expect(registry.getExpressions()).toEqual([])

  describe '::serialize', ->
    it 'serializes the registry with the function content', ->
      registry.createExpression 'dummy', 'foo'
      registry.createExpression 'dummy2', 'bar', (a,b,c) -> a + b - c

      serialized = registry.serialize()

      expect(serialized.regexpString).toEqual('(foo)|(bar)')
      expect(serialized.expressions.dummy).toEqual({
        name: 'dummy'
        regexpString: 'foo'
        handle: undefined
        priority: 0
        scopes: ['*']
      })

      expect(serialized.expressions.dummy2).toEqual({
        name: 'dummy2'
        regexpString: 'bar'
        handle: registry.getExpression('dummy2').handle.toString()
        priority: 0
        scopes: ['*']
      })

  describe '.deserialize', ->
    it 'deserializes the provided expressions using the specified model', ->
      serialized =
        regexpString: 'foo|bar'
        expressions:
          dummy:
            name: 'dummy'
            regexpString: 'foo'
            handle: 'function (a,b,c) { return a + b - c; }'
            priority: 0
            scopes: ['*']

      deserialized = ExpressionsRegistry.deserialize(serialized, Dummy)

      expect(deserialized.getRegExp()).toEqual('foo|bar')
      expect(deserialized.getExpression('dummy').name).toEqual('dummy')
      expect(deserialized.getExpression('dummy').regexpString).toEqual('foo')
      expect(deserialized.getExpression('dummy').handle(1,2,3)).toEqual(0)
