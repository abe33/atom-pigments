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

        if context?
          it 'stores the variables used by the color in property', ->
            expect(parser.parse(expression, context).variables.sort()).toEqual(context.getVariablesNames().sort())

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

  itParses('darken(cyan, 20%)').asColor(0, 153, 153)
  itParses('darken(#fff, 100%)').asColor(0, 0, 0)
  itParses('darken(cyan, $r)').asInvalid()
  itParses('darken($c, $r)').withContext({
    '$c': 'cyan'
    '$r': '20%'
  }).asColor(0, 153, 153)
  itParses('darken($a, $r)').withContext({
    '$a': 'rgba($c, 1)'
    '$c': 'cyan'
    '$r': '20%'
  }).asColor(0, 153, 153)

  itParses('lighten(cyan, 20%)').asColor(102, 255, 255)
  itParses('lighten(#000, 100%)').asColor(255, 255, 255)
  itParses('lighten(cyan, $r)').asInvalid()
  itParses('lighten($c, $r)').withContext({
    '$c': 'cyan'
    '$r': '20%'
  }).asColor(102, 255, 255)
  itParses('lighten($a, $r)').withContext({
    '$a': 'rgba($c, 1)'
    '$c': 'cyan'
    '$r': '20%'
  }).asColor(102, 255, 255)

  itParses('transparentize(cyan, 50%)').asColor(0, 255, 255, 0.5)
  itParses('transparentize(cyan, 0.5)').asColor(0, 255, 255, 0.5)
  itParses('transparentize(cyan, .5)').asColor(0, 255, 255, 0.5)
  itParses('fadein(cyan, 0.5)').asColor(0, 255, 255, 0.5)
  itParses('fadein(cyan, .5)').asColor(0, 255, 255, 0.5)
  itParses('fadein(cyan, @r)').asInvalid()
  itParses('fadein(@c, @r)').withContext({
    '@c': 'cyan'
    '@r': '0.5'
  }).asColor(0, 255, 255, 0.5)
  itParses('fadein(@a, @r)').withContext({
    '@a': 'rgba(@c, 1)'
    '@c': 'cyan'
    '@r': '0.5'
  }).asColor(0, 255, 255, 0.5)

  itParses('opacify(0x7800FFFF, 50%)').asColor(0, 255, 255, 1)
  itParses('opacify(0x7800FFFF, 0.5)').asColor(0, 255, 255, 1)
  itParses('opacify(0x7800FFFF, .5)').asColor(0, 255, 255, 1)
  itParses('fadeout(0x7800FFFF, 0.5)').asColor(0, 255, 255, 1)
  itParses('fadeout(0x7800FFFF, .5)').asColor(0, 255, 255, 1)
  itParses('fadeout(0x7800FFFF, @r)').asInvalid()
  itParses('fadeout(@c, @r)').withContext({
    '@c': '0x7800FFFF'
    '@r': '0.5'
  }).asColor(0, 255, 255, 1)
  itParses('fadeout(@a, @r)').withContext({
    '@a': 'rgba(@c, 1)'
    '@c': '0x7800FFFF'
    '@r': '0.5'
  }).asColor(0, 255, 255, 1)

  itParses('saturate(#855, 20%)').asColor(158, 63, 63)
  itParses('saturate(#855, 0.2)').asColor(158, 63, 63)
  itParses('saturate(#855, @r)').asInvalid()
  itParses('saturate(@c, @r)').withContext({
    '@c': '#855'
    '@r': '0.2'
  }).asColor(158, 63, 63)
  itParses('saturate(@a, @r)').withContext({
    '@a': 'rgba(@c, 1)'
    '@c': '#855'
    '@r': '0.2'
  }).asColor(158, 63, 63)

  itParses('desaturate(#9e3f3f, 20%)').asColor(136, 85, 85)
  itParses('desaturate(#9e3f3f, 0.2)').asColor(136, 85, 85)
  itParses('desaturate(#9e3f3f, .2)').asColor(136, 85, 85)
  itParses('desaturate(#9e3f3f, @r)').asInvalid()
  itParses('desaturate(@c, @r)').withContext({
    '@c': '#9e3f3f'
    '@r': '0.2'
  }).asColor(136, 85, 85)
  itParses('desaturate(@a, @r)').withContext({
    '@a': 'rgba(@c, 1)'
    '@c': '#9e3f3f'
    '@r': '0.2'
  }).asColor(136, 85, 85)

  itParses('grayscale(#9e3f3f)').asColor(111, 111, 111)
  itParses('greyscale(#9e3f3f)').asColor(111, 111, 111)
  itParses('grayscale(@c)').asInvalid()
  itParses('grayscale(@c)').withContext({
    '@c': '#9e3f3f'
  }).asColor(111, 111, 111)
  itParses('grayscale(@a)').withContext({
    '@a': 'rgba(@c, 1)'
    '@c': '#9e3f3f'
  }).asColor(111, 111, 111)

  itParses('invert(#9e3f3f)').asColor(97, 192, 192)
  itParses('invert(@c)').asInvalid()
  itParses('invert(@c)').withContext({
    '@c': '#9e3f3f'
  }).asColor(97, 192, 192)
  itParses('invert(@a)').withContext({
    '@a': 'rgba(@c, 1)'
    '@c': '#9e3f3f'
  }).asColor(97, 192, 192)

  itParses('adjust-hue(#811, 45deg)').asColor(136, 106, 17)
  itParses('adjust-hue(#811, -45deg)').asColor(136, 17, 106)
  itParses('adjust-hue(#811, 45%)').asColor(136, 106, 17)
  itParses('adjust-hue(#811, -45%)').asColor(136, 17, 106)
  itParses('adjust-hue($c, $r)').asInvalid()
  itParses('adjust-hue($c, $r)').withContext({
    '$c': '#811'
    '$r': '-45deg'
  }).asColor(136, 17, 106)
  itParses('adjust-hue($a, $r)').withContext({
    '$a': 'rgba($c, 0.5)'
    '$c': '#811'
    '$r': '-45deg'
  }).asColor(136, 17, 106, 0.5)

  itParses('mix(red, blue)').asColor(127, 0, 127)
  itParses('mix(red, blue, 25%)').asColor(63, 0, 191)
  itParses('mix($a, $b, $r)').asInvalid()
  itParses('mix($a, $b, $r)').withContext({
    '$a': 'red'
    '$b': 'blue'
    '$r': '25%'
  }).asColor(63, 0, 191)
  itParses('mix($c, $d, $r)').withContext({
    '$a': 'red'
    '$b': 'blue'
    '$c': 'rgba($a, 1)'
    '$d': 'rgba($b, 1)'
    '$r': '25%'
  }).asColor(63, 0, 191)

  itParses('tint(#fd0cc7,66%)').asColor(254, 172, 235)
  itParses('tint($c,$r)').asInvalid()
  itParses('tint($c,$r)').withContext({
    '$c': '#fd0cc7'
    '$r': '66%'
  }).asColor(254, 172, 235)
  itParses('tint($c,$r)').withContext({
    '$a': '#fd0cc7'
    '$c': 'rgba($a, 0.9)'
    '$r': '66%'
  }).asColor(254, 172, 235, 0.966)

  itParses('shade(#fd0cc7,66%)').asColor(86, 4, 67)
  itParses('shade($c,$r)').asInvalid()
  itParses('shade($c,$r)').withContext({
    '$c': '#fd0cc7'
    '$r': '66%'
  }).asColor(86, 4, 67)
  itParses('shade($c,$r)').withContext({
    '$a': '#fd0cc7'
    '$c': 'rgba($a, 0.9)'
    '$r': '66%'
  }).asColor(86, 4, 67, 0.966)

  itParses('color(#fd0cc7 tint(66%))').asColor(254, 172, 236)

  itParses('adjust-color(#102030, $red: -5, $blue: 5)', 11, 32, 53)
  itParses('adjust-color(hsl(25, 100%, 80%), $lightness: -30%, $alpha: -0.4)', 255, 106, 0, 0.6)
  itParses('adjust-color($c, $red: $a, $blue: $b)').asInvalid()
  itParses('adjust-color($c, $red: $a, $blue: $b)').withContext({
    '$a': '-5'
    '$b': '5'
    '$c': '#102030'
  }).asColor(11, 32, 53)
  itParses('adjust-color($d, $red: $a, $blue: $b)').withContext({
    '$a': '-5'
    '$b': '5'
    '$c': '#102030'
    '$d': 'rgba($c, 1)'
  }).asColor(11, 32, 53)

  itParses('scale-color(rgb(200, 150, 170), $green: -40%, $blue: 70%)').asColor(200, 90, 230)
  itParses('change-color(rgb(200, 150, 170), $green: 40, $blue: 70)').asColor(200, 40, 70)
  itParses('scale-color($c, $green: $a, $blue: $b)').asInvalid()
  itParses('scale-color($c, $green: $a, $blue: $b)').withContext({
    '$a': '-40%'
    '$b': '70%'
    '$c': 'rgb(200, 150, 170)'
  }).asColor(200, 90, 230)
  itParses('scale-color($d, $green: $a, $blue: $b)').withContext({
    '$a': '-40%'
    '$b': '70%'
    '$c': 'rgb(200, 150, 170)'
    '$d': 'rgba($c, 1)'
  }).asColor(200, 90, 230)
