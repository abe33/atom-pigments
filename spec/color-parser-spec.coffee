require './spec-helper'

ColorParser = require '../lib/color-parser'

describe 'ColorParser', ->
  [parser] = []

  itParses = (expression) ->
    asColor: (args...) ->
      it "parses '#{expression}' as a color", ->
        expect(parser.parse(expression)).toBeColor(args...)

  describe 'without any context', ->
    beforeEach ->
      parser = new ColorParser

    itParses('#7fff7f00').asColor(255, 127, 0, 0.5)
    itParses('#ff7f00').asColor(255, 127, 0)
    itParses('#f70').asColor(255, 119, 0)

    itParses('0xff7f00').asColor(255, 127, 0)
    itParses('0x00ff7f00').asColor(255, 127, 0, 0)

    itParses('rgb(255,127,0)').asColor(255, 127, 0)
