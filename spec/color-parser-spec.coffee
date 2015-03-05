require './spec-helper'

ColorParser = require '../lib/color-parser'
ColorContext = require '../lib/color-context'

describe 'ColorParser', ->
  [parser] = []

  itParses = (expression) ->
    description: ''
    asColor: (args...) ->
      context = @context
      describe @description, ->
        it "parses '#{expression}' as a color", ->
          expect(parser.parse(expression, context)).toBeColor(args...)

    asUndefined: ->
      context = @context
      describe @description, ->
        it "does not parse '#{expression}' and return undefined", ->
          expect(parser.parse(expression, context)).toBeUndefined()

    asInvalid: ->
      context = @context
      describe @description, ->
        it "parses '#{expression}' as an invalid color", ->
          expect(parser.parse(expression, context)).not.toBeValid()

    withContext: (variables) ->
      ctx = {}
      ctx[key] = {value} for key,value of variables
      @context = new ColorContext(undefined, ctx)
      @description = "with variables context #{jasmine.pp variables} "

      return this

  beforeEach ->
    parser = new ColorParser

  itParses('#7fff7f00').asColor(255, 127, 0, 0.5)
  itParses('#ff7f00').asColor(255, 127, 0)
  itParses('#f70').asColor(255, 119, 0)

  itParses('0xff7f00').asColor(255, 127, 0)
  itParses('0x00ff7f00').asColor(255, 127, 0, 0)

  itParses('rgb(255,127,0)').asColor(255, 127, 0)
  itParses('rgb(255,127,0)').asColor(255, 127, 0)
  itParses('rgb($r,$g,$b)').asInvalid()
  itParses('rgb($r,$g,$b)').withContext({
    '$r': '255'
    '$g': '127'
    '$b': '0'
  }).asColor(255, 127, 0)

  itParses('rgba(255,127,0,0.5)').asColor(255, 127, 0, 0.5)
  itParses('rgba(255,127,0,.5)').asColor(255, 127, 0, 0.5)
  itParses('rgba(255,127,0,)').asUndefined()
  itParses('rgba($r,$g,$b,$a)').asInvalid()
  itParses('rgba($r,$g,$b,$a)').withContext({
    '$r': '255'
    '$g': '127'
    '$b': '0'
    '$a': '0.5'
  }).asColor(255, 127, 0, 0.5)

  itParses('rgba(green, 0.5)').asColor(0, 128, 0, 0.5)
  itParses('rgba($c,$a,)').asUndefined()
  itParses('rgba($c,$a)').asInvalid()
  itParses('rgba($c,1)').asInvalid()
  itParses('rgba($c,$a)').withContext({
    '$c': 'green'
    '$a': '0.5'
  }).asColor(0, 128, 0, 0.5)

  itParses('hsl(200,50%,50%)').asColor(64, 149, 191)
  itParses('hsl($h,$s,$l,)').asUndefined()
  itParses('hsl($h,$s,$l)').asInvalid()
  itParses('hsl($h,$s,$l)').withContext({
    '$h': '200'
    '$s': '50%'
    '$l': '50%'
  }).asColor(64, 149, 191)

  itParses('hsla(200,50%,50%,0.5)').asColor(64, 149, 191, 0.5)
  itParses('hsla(200,50%,50%,.5)').asColor(64, 149, 191, 0.5)
  itParses('hsla(200,50%,50%,)').asUndefined()
  itParses('hsla($h,$s,$l,$a)').asInvalid()
  itParses('hsla($h,$s,$l,$a)').withContext({
    '$h': '200'
    '$s': '50%'
    '$l': '50%'
    '$a': '0.5'
  }).asColor(64, 149, 191, 0.5)

  itParses('hsv(200,50%,50%)').asColor(64, 106, 128)
  itParses('hsv($h,$s,$v,)').asUndefined()
  itParses('hsv($h,$s,$v)').asInvalid()
  itParses('hsv($h,$s,$v)').withContext({
    '$h': '200'
    '$s': '50%'
    '$v': '50%'
  }).asColor(64, 106, 128)

  itParses('hsva(200,50%,50%,0.5)').asColor(64, 106, 128, 0.5)
  itParses('hsva(200,50%,50%,.5)').asColor(64, 106, 128, 0.5)
  itParses('hsva(200,50%,50%,)').asUndefined()
  itParses('hsva($h,$s,$v,$a)').asInvalid()
  itParses('hsva($h,$s,$v,$a)').withContext({
    '$h': '200'
    '$s': '50%'
    '$v': '50%'
    '$a': '0.5'
  }).asColor(64, 106, 128, 0.5)

  itParses('hwb(210,40%,40%)').asColor(102, 128, 153)
  itParses('hwb(210,40%,40%, 0.5)').asColor(102, 128, 153, 0.5)
  itParses('hwb($h,$w,$b,)').asUndefined()
  itParses('hwb($h,$w,$b)').asInvalid()
  itParses('hwb($h,$w,$b,$a)').asInvalid()
  itParses('hwb($h,$w,$b)').withContext({
    '$h': '210'
    '$w': '40%'
    '$b': '40%'
  }).asColor(102, 128, 153)
  itParses('hwb($h,$w,$b,$a)').withContext({
    '$h': '210'
    '$w': '40%'
    '$b': '40%'
    '$a': '0.5'
  }).asColor(102, 128, 153, 0.5)

  itParses('gray(100%)').asColor(255, 255, 255)
  itParses('gray(100%, 0.5)').asColor(255, 255, 255, 0.5)
  itParses('gray($c, $a,)').asUndefined()
  itParses('gray($c, $a)').asInvalid()
  itParses('gray($c, $a)').withContext({
    '$c': '100%'
    '$a': '0.5'
  }).asColor(255, 255, 255, 0.5)

  itParses('yellowgreen').asColor('#9acd32')
  itParses('YELLOWGREEN').asColor('#9acd32')
  itParses('yellowGreen').asColor('#9acd32')
  itParses('YellowGreen').asColor('#9acd32')
  itParses('yellow_green').asColor('#9acd32')
  itParses('YELLOW_GREEN').asColor('#9acd32')
