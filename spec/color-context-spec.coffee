
ColorContext = require '../lib/color-context'
ColorParser = require '../lib/color-parser'

describe 'ColorContext', ->
  [context, parser] = []

  itParses = (expression) ->
    asUndefinedColor: ->
      it "parses '#{expression}' as undefined", ->
        expect(context.readColor(expression)).toBeUndefined()

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

    asColor: (expected...) ->
      it "parses '#{expression}' as a color with value of #{jasmine.pp expected}", ->
        expect(context.readColor(expression)).toBeColor(expected...)

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

    itParses('red').asColor(255, 0, 0)
    itParses('#ff0000').asColor(255, 0, 0)
    itParses('rgb(255,127,0)').asColor(255, 127, 0)

  describe 'with a variables hash', ->
    createVar = (name, value) -> {value, name}

    createColorVar = (name, value) ->
      v = createVar(name, value)
      v.isColor = true
      v

    beforeEach ->

      variables =[
        createVar 'x', '10'
        createVar 'y', '0.1'
        createVar 'z', '10%'
        createColorVar 'c', 'rgb(255,127,0)'
      ]

      context = new ColorContext(variables)

    itParses('x').asInt(10)
    itParses('y').asFloat(0.1)
    itParses('z').asIntOrPercent(26)
    itParses('z').asFloatOrPercent(0.1)

    itParses('c').asColorExpression('rgb(255,127,0)')
    itParses('c').asColor(255, 127, 0)

    describe 'that contains invalid colors', ->
      beforeEach ->
        variables =[
          createVar '@text-height', '@scale-b-xxl * 1rem'
          createVar '@component-line-height', '@text-height'
          createVar '@list-item-height', '@component-line-height'
        ]

        context = new ColorContext(variables)

      itParses('@list-item-height').asUndefinedColor()
