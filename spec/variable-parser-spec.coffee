VariableParser = require '../lib/variable-parser'

describe 'VariableParser', ->
  [parser] = []

  itParses = (expression) ->
    description: ''
    as: (variable, lastIndex) ->
      [expectedName] = Object.keys(variable)
      expectedValue = variable[expectedName]
      lastIndex ?= expression.length

      it "parses the '#{expression}' as a color variable with name '#{expectedName}' and value '#{expectedValue}'", ->
        [{name, value, type}] = parser.parse(expression)
        expect(name).toEqual(expectedName)
        expect(value).toEqual(expectedValue)
        expect(value).toEqual(expectedValue)

      this

    withType: (type) ->
      it "parses '#{expression}' as a variable of type #{type}", ->
        [{type}] = parser.parse(expression)
        expect(type).toEqual('non-color')

      this

  beforeEach ->
    parser = new VariableParser

  itParses('color = white').as('color': 'white')

  itParses('non-color = 10px').as('non-color': '10px')
