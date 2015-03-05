
ColorContext = require '../lib/color-context'

describe 'ColorContext', ->
  [context] = []

  itParses = (expression) ->
    asInt: (expected) ->
      it "parses '#{expression}' as an integer with value of #{expected}", ->
        expect(context.readInt(expression)).toEqual(expected)

    asFloat: (expected) ->
      it "parses '#{expression}' as a float with value of #{expected}", ->
        expect(context.readFloat(expression)).toEqual(expected)

    asIntOrPercent: (expected) ->
      it "parses '#{expression}' as an integer or a percentage with value of #{expected}", ->
        expect(context.readIntOrPercent(expression)).toEqual(expected)

    asFloatOrPercent: (expected) ->
      it "parses '#{expression}' as a float or a percentage with value of #{expected}", ->
        expect(context.readFloatOrPercent(expression)).toEqual(expected)

    asColorExpression: (expected) ->
      it "parses '#{expression}' as a color expression", ->
        expect(context.readColorExpression(expression)).toEqual(expected)

    asColor: (expected) ->
      it "parses '#{expression}' as a color with value of #{jasmine.pp expected}", ->
        expect(context.readColor(expression)).toBeColor(expected)

  describe 'created without any variables', ->
    beforeEach ->
      context = new ColorContext

    itParses('10').asInt(10)

    itParses('10').asFloat(10)
    itParses('0.5').asFloat(0.5)
    itParses('.5').asFloat(0.5)

    itParses('10').asIntOrPercent(10)
    itParses('10%').asIntOrPercent(26)

    itParses('0.1').asFloatOrPercent(0.1)
    itParses('10%').asFloatOrPercent(0.1)

    itParses('red').asColorExpression('red')

    itParses('red').asColor('#ff0000')
