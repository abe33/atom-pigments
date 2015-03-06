VariableParser = require '../lib/variable-parser'

describe 'VariableParser', ->
  [parser] = []

  itParses = (expression) ->
    description: ''
    asColor: (variable) ->
      [expectedName] = Object.keys(variable)
      expectedValue = variable[expectedName]

      it "parses the '#{expression}' as a color variable with name '#{expectedName}' and value '#{expectedValue}'", ->
        [{name, value, type}] = parser.parse(expression)
        expect(name).toEqual(expectedName)
        expect(value).toEqual(expectedValue)
        # expect(type).toEqual('color')

    asNonColor: (variable) ->
      [expectedName] = Object.keys(variable)
      expectedValue = variable[expectedName]

      it "parses '#{expression}' as a variable with name '#{expectedName}' and value '#{expectedValue}'", ->
        [{name, value, type}] = parser.parse(expression)
        expect(name).toEqual(expectedName)
        expect(value).toEqual(expectedValue)
        # expect(type).toEqual('non-color')

  beforeEach ->
    parser = new VariableParser

  itParses('color = white').asColor('color': 'white')

  itParses('non-color = 10px').asNonColor('non-color': '10px')
