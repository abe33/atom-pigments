require './helpers/matchers'

ColorParser = require '../lib/color-parser'
ColorContext = require '../lib/color-context'
ColorExpression = require '../lib/color-expression'
registry = require '../lib/color-expressions'

describe 'ColorParser', ->
  [parser] = []

  asColor = (value) -> "color:#{value}"

  getParser = (context) ->
    context = new ColorContext(context ? {registry})
    context.parser

  itParses = (expression) ->
    description: ''
    asColor: (r,g,b,a=1) ->
      context = @context
      describe @description, ->
        beforeEach -> parser = getParser(context)

        it "parses '#{expression}' as a color", ->
          if context?
            expect(parser.parse(expression, @scope ? 'less')).toBeColor(r,g,b,a, Object.keys(context).sort())
          else
            expect(parser.parse(expression, @scope ? 'less')).toBeColor(r,g,b,a)

    asUndefined: ->
      context = @context
      describe @description, ->
        beforeEach -> parser = getParser(context)

        it "does not parse '#{expression}' and return undefined", ->
          expect(parser.parse(expression, @scope ? 'less')).toBeUndefined()

    asInvalid: ->
      context = @context
      describe @description, ->
        beforeEach -> parser = getParser(context)

        it "parses '#{expression}' as an invalid color", ->
          expect(parser.parse(expression, @scope ? 'less')).not.toBeValid()

    withContext: (variables) ->
      vars = []
      colorVars = []
      path = "/path/to/file.styl"
      for name,value of variables
        if value.indexOf('color:') isnt -1
          value = value.replace('color:', '')
          vars.push {name, value, path}
          colorVars.push {name, value, path}

        else
          vars.push {name, value, path}
      @context = {variables: vars, colorVariables: colorVars, registry}
      @description = "with variables context #{jasmine.pp variables} "

      return this

  itParses('@list-item-height').withContext({
      '@text-height': '@scale-b-xxl * 1rem'
      '@component-line-height': '@text-height'
      '@list-item-height': '@component-line-height'
    }).asUndefined()

  itParses('$text-color !default').withContext({
    '$text-color': asColor 'cyan'
  }).asColor(0,255,255)

  itParses('c').withContext({'c': 'c'}).asUndefined()
  itParses('c').withContext({
    'c': 'd'
    'd': 'e'
    'e': 'c'
  }).asUndefined()

  itParses('#ff7f00').asColor(255, 127, 0)
  itParses('#f70').asColor(255, 119, 0)

  itParses('#ff7f00cc').asColor(255, 127, 0, 0.8)
  itParses('#f70c').asColor(255, 119, 0, 0.8)

  itParses('0xff7f00').asColor(255, 127, 0)
  itParses('0x00ff7f00').asColor(255, 127, 0, 0)

  describe 'in context other than css and pre-processors', ->
    beforeEach -> @scope = 'xaml'

    itParses('#ccff7f00').asColor(255, 127, 0, 0.8)

  itParses('rgb(255,127,0)').asColor(255, 127, 0)
  itParses('rgb(255,127,0)').asColor(255, 127, 0)
  itParses('rgb($r,$g,$b)').asInvalid()
  itParses('rgb($r,0,0)').asInvalid()
  itParses('rgb(0,$g,0)').asInvalid()
  itParses('rgb(0,0,$b)').asInvalid()
  itParses('rgb($r,$g,$b)').withContext({
    '$r': '255'
    '$g': '127'
    '$b': '0'
  }).asColor(255, 127, 0)

  itParses('rgba(255,127,0,0.5)').asColor(255, 127, 0, 0.5)
  itParses('rgba(255,127,0,.5)').asColor(255, 127, 0, 0.5)
  itParses('rgba(255,127,0,)').asUndefined()
  itParses('rgba($r,$g,$b,$a)').asInvalid()
  itParses('rgba($r,0,0,0)').asInvalid()
  itParses('rgba(0,$g,0,0)').asInvalid()
  itParses('rgba(0,0,$b,0)').asInvalid()
  itParses('rgba(0,0,0,$a)').asInvalid()
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
  itParses('rgba($c, $r)').withContext({
    '$c': asColor 'hsv($h, $s, $v)'
    '$r': '1'
  }).asInvalid()
  itParses('rgba($c,$a)').withContext({
    '$c': asColor 'green'
    '$a': '0.5'
  }).asColor(0, 128, 0, 0.5)

  itParses('hsl(200,50%,50%)').asColor(64, 149, 191)
  itParses('hsl(200,50,50)').asColor(64, 149, 191)
  itParses('hsl(200.5,50.5,50.5)').asColor(65, 150, 193)
  itParses('hsl($h,$s,$l,)').asUndefined()
  itParses('hsl($h,$s,$l)').asInvalid()
  itParses('hsl($h,0%,0%)').asInvalid()
  itParses('hsl(0,$s,0%)').asInvalid()
  itParses('hsl(0,0%,$l)').asInvalid()
  itParses('hsl($h,$s,$l)').withContext({
    '$h': '200'
    '$s': '50%'
    '$l': '50%'
  }).asColor(64, 149, 191)

  itParses('hsla(200,50%,50%,0.5)').asColor(64, 149, 191, 0.5)
  itParses('hsla(200,50%,50%,.5)').asColor(64, 149, 191, 0.5)
  itParses('hsla(200,50,50,.5)').asColor(64, 149, 191, 0.5)
  itParses('hsla(200.5,50.5,50.5,.5)').asColor(65, 150, 193, 0.5)
  itParses('hsla(200,50%,50%,)').asUndefined()
  itParses('hsla($h,$s,$l,$a)').asInvalid()
  itParses('hsla($h,0%,0%,0)').asInvalid()
  itParses('hsla(0,$s,0%,0)').asInvalid()
  itParses('hsla(0,0%,$l,0)').asInvalid()
  itParses('hsla(0,0%,0%,$a)').asInvalid()
  itParses('hsla($h,$s,$l,$a)').withContext({
    '$h': '200'
    '$s': '50%'
    '$l': '50%'
    '$a': '0.5'
  }).asColor(64, 149, 191, 0.5)

  itParses('hsv(200,50%,50%)').asColor(64, 106, 128)
  itParses('hsb(200,50%,50%)').asColor(64, 106, 128)
  itParses('hsb(200,50,50)').asColor(64, 106, 128)
  itParses('hsb(200.5,50.5,50.5)').asColor(64, 107, 129)
  itParses('hsv($h,$s,$v,)').asUndefined()
  itParses('hsv($h,$s,$v)').asInvalid()
  itParses('hsv($h,0%,0%)').asInvalid()
  itParses('hsv(0,$s,0%)').asInvalid()
  itParses('hsv(0,0%,$v)').asInvalid()
  itParses('hsv($h,$s,$v)').withContext({
    '$h': '200'
    '$s': '50%'
    '$v': '50%'
  }).asColor(64, 106, 128)

  itParses('hsva(200,50%,50%,0.5)').asColor(64, 106, 128, 0.5)
  itParses('hsva(200,50,50,0.5)').asColor(64, 106, 128, 0.5)
  itParses('hsba(200,50%,50%,0.5)').asColor(64, 106, 128, 0.5)
  itParses('hsva(200,50%,50%,.5)').asColor(64, 106, 128, 0.5)
  itParses('hsva(200.5,50.5,50.5,.5)').asColor(64, 107, 129, 0.5)
  itParses('hsva(200,50%,50%,)').asUndefined()
  itParses('hsva($h,$s,$v,$a)').asInvalid()
  itParses('hsva($h,0%,0%,0)').asInvalid()
  itParses('hsva(0,$s,0%,0)').asInvalid()
  itParses('hsva(0,0%,$v,0)').asInvalid()
  itParses('hsva($h,$s,$v,$a)').withContext({
    '$h': '200'
    '$s': '50%'
    '$v': '50%'
    '$a': '0.5'
  }).asColor(64, 106, 128, 0.5)

  itParses('hwb(210,40%,40%)').asColor(102, 128, 153)
  itParses('hwb(210,40,40)').asColor(102, 128, 153)
  itParses('hwb(210,40%,40%, 0.5)').asColor(102, 128, 153, 0.5)
  itParses('hwb(210.5,40.5,40.5)').asColor(103, 128, 152)
  itParses('hwb(210.5,40.5%,40.5%, 0.5)').asColor(103, 128, 152, 0.5)
  itParses('hwb($h,$w,$b,)').asUndefined()
  itParses('hwb($h,$w,$b)').asInvalid()
  itParses('hwb($h,0%,0%)').asInvalid()
  itParses('hwb(0,$w,0%)').asInvalid()
  itParses('hwb(0,0%,$b)').asInvalid()
  itParses('hwb($h,0%,0%,0)').asInvalid()
  itParses('hwb(0,$w,0%,0)').asInvalid()
  itParses('hwb(0,0%,$b,0)').asInvalid()
  itParses('hwb(0,0%,0%,$a)').asInvalid()
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

  itParses('cmyk(0,0.5,1,0)').asColor('#ff7f00')
  itParses('cmyk(c,m,y,k)').withContext({
    'c': '0'
    'm': '0.5'
    'y': '1'
    'k': '0'
  }).asColor('#ff7f00')
  itParses('cmyk(c,m,y,k)').asInvalid()

  itParses('gray(100%)').asColor(255, 255, 255)
  itParses('gray(100)').asColor(255, 255, 255)
  itParses('gray(100%, 0.5)').asColor(255, 255, 255, 0.5)
  itParses('gray($c, $a,)').asUndefined()
  itParses('gray($c, $a)').asInvalid()
  itParses('gray(0%, $a)').asInvalid()
  itParses('gray($c, 0)').asInvalid()
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
  itParses('>YELLOW_GREEN').asColor('#9acd32')

  itParses('darken(cyan, 20%)').asColor(0, 153, 153)
  itParses('darken(cyan, 20)').asColor(0, 153, 153)
  itParses('darken(#fff, 100%)').asColor(0, 0, 0)
  itParses('darken(cyan, $r)').asInvalid()
  itParses('darken($c, $r)').withContext({
    '$c': asColor 'hsv($h, $s, $v)'
    '$r': '1'
  }).asInvalid()
  itParses('darken($c, $r)').withContext({
    '$c': asColor 'cyan'
    '$r': '20%'
  }).asColor(0, 153, 153)
  itParses('darken($a, $r)').withContext({
    '$a': asColor 'rgba($c, 1)'
    '$c': asColor 'cyan'
    '$r': '20%'
  }).asColor(0, 153, 153)

  itParses('lighten(cyan, 20%)').asColor(102, 255, 255)
  itParses('lighten(cyan, 20)').asColor(102, 255, 255)
  itParses('lighten(#000, 100%)').asColor(255, 255, 255)
  itParses('lighten(cyan, $r)').asInvalid()
  itParses('lighten($c, $r)').withContext({
    '$c': asColor 'hsv($h, $s, $v)'
    '$r': '1'
  }).asInvalid()
  itParses('lighten($c, $r)').withContext({
    '$c': asColor 'cyan'
    '$r': '20%'
  }).asColor(102, 255, 255)
  itParses('lighten($a, $r)').withContext({
    '$a': asColor 'rgba($c, 1)'
    '$c': asColor 'cyan'
    '$r': '20%'
  }).asColor(102, 255, 255)

  itParses('transparentize(cyan, 50%)').asColor(0, 255, 255, 0.5)
  itParses('transparentize(cyan, 50)').asColor(0, 255, 255, 0.5)
  itParses('transparentize(cyan, 0.5)').asColor(0, 255, 255, 0.5)
  itParses('transparentize(cyan, .5)').asColor(0, 255, 255, 0.5)
  itParses('fadeout(cyan, 0.5)').asColor(0, 255, 255, 0.5)
  itParses('fade-out(cyan, 0.5)').asColor(0, 255, 255, 0.5)
  itParses('fade_out(cyan, 0.5)').asColor(0, 255, 255, 0.5)
  itParses('fadeout(cyan, .5)').asColor(0, 255, 255, 0.5)
  itParses('fadeout(cyan, @r)').asInvalid()
  itParses('fadeout($c, $r)').withContext({
    '$c': asColor 'hsv($h, $s, $v)'
    '$r': '1'
  }).asInvalid()
  itParses('fadeout(@c, @r)').withContext({
    '@c': asColor 'cyan'
    '@r': '0.5'
  }).asColor(0, 255, 255, 0.5)
  itParses('fadeout(@a, @r)').withContext({
    '@a': asColor 'rgba(@c, 1)'
    '@c': asColor 'cyan'
    '@r': '0.5'
  }).asColor(0, 255, 255, 0.5)

  itParses('opacify(0x7800FFFF, 50%)').asColor(0, 255, 255, 1)
  itParses('opacify(0x7800FFFF, 50)').asColor(0, 255, 255, 1)
  itParses('opacify(0x7800FFFF, 0.5)').asColor(0, 255, 255, 1)
  itParses('opacify(0x7800FFFF, .5)').asColor(0, 255, 255, 1)
  itParses('fadein(0x7800FFFF, 0.5)').asColor(0, 255, 255, 1)
  itParses('fade-in(0x7800FFFF, 0.5)').asColor(0, 255, 255, 1)
  itParses('fade_in(0x7800FFFF, 0.5)').asColor(0, 255, 255, 1)
  itParses('fadein(0x7800FFFF, .5)').asColor(0, 255, 255, 1)
  itParses('fadein(0x7800FFFF, @r)').asInvalid()
  itParses('fadein($c, $r)').withContext({
    '$c': asColor 'hsv($h, $s, $v)'
    '$r': '1'
  }).asInvalid()
  itParses('fadein(@c, @r)').withContext({
    '@c': asColor '0x7800FFFF'
    '@r': '0.5'
  }).asColor(0, 255, 255, 1)
  itParses('fadein(@a, @r)').withContext({
    '@a': asColor 'rgba(@c, 1)'
    '@c': asColor '0x7800FFFF'
    '@r': '0.5'
  }).asColor(0, 255, 255, 1)

  itParses('saturate(#855, 20%)').asColor(158, 63, 63)
  itParses('saturate(#855, 20)').asColor(158, 63, 63)
  itParses('saturate(#855, 0.2)').asColor(158, 63, 63)
  itParses('saturate(#855, @r)').asInvalid()
  itParses('saturate($c, $r)').withContext({
    '$c': asColor 'hsv($h, $s, $v)'
    '$r': '1'
  }).asInvalid()
  itParses('saturate(@c, @r)').withContext({
    '@c': asColor '#855'
    '@r': '0.2'
  }).asColor(158, 63, 63)
  itParses('saturate(@a, @r)').withContext({
    '@a': asColor 'rgba(@c, 1)'
    '@c': asColor '#855'
    '@r': '0.2'
  }).asColor(158, 63, 63)

  itParses('desaturate(#9e3f3f, 20%)').asColor(136, 85, 85)
  itParses('desaturate(#9e3f3f, 20)').asColor(136, 85, 85)
  itParses('desaturate(#9e3f3f, 0.2)').asColor(136, 85, 85)
  itParses('desaturate(#9e3f3f, .2)').asColor(136, 85, 85)
  itParses('desaturate(#9e3f3f, @r)').asInvalid()
  itParses('desaturate($c, $r)').withContext({
    '$c': asColor 'hsv($h, $s, $v)'
    '$r': '1'
  }).asInvalid()
  itParses('desaturate(@c, @r)').withContext({
    '@c': asColor '#9e3f3f'
    '@r': '0.2'
  }).asColor(136, 85, 85)
  itParses('desaturate(@a, @r)').withContext({
    '@a': asColor 'rgba(@c, 1)'
    '@c': asColor '#9e3f3f'
    '@r': '0.2'
  }).asColor(136, 85, 85)

  itParses('grayscale(#9e3f3f)').asColor(111, 111, 111)
  itParses('greyscale(#9e3f3f)').asColor(111, 111, 111)
  itParses('grayscale(@c)').asInvalid()
  itParses('grayscale($c)').withContext({
    '$c': asColor 'hsv($h, $s, $v)'
  }).asInvalid()
  itParses('grayscale(@c)').withContext({
    '@c': asColor '#9e3f3f'
  }).asColor(111, 111, 111)
  itParses('grayscale(@a)').withContext({
    '@a': asColor 'rgba(@c, 1)'
    '@c': asColor '#9e3f3f'
  }).asColor(111, 111, 111)

  itParses('invert(#9e3f3f)').asColor(97, 192, 192)
  itParses('invert(@c)').asInvalid()
  itParses('invert($c)').withContext({
    '$c': asColor 'hsv($h, $s, $v)'
  }).asInvalid()
  itParses('invert(@c)').withContext({
    '@c': asColor '#9e3f3f'
  }).asColor(97, 192, 192)
  itParses('invert(@a)').withContext({
    '@a': asColor 'rgba(@c, 1)'
    '@c': asColor '#9e3f3f'
  }).asColor(97, 192, 192)

  itParses('adjust-hue(#811, 45deg)').asColor(136, 106, 17)
  itParses('adjust-hue(#811, -45deg)').asColor(136, 17, 106)
  itParses('adjust-hue(#811, 45%)').asColor(136, 106, 17)
  itParses('adjust-hue(#811, -45%)').asColor(136, 17, 106)
  itParses('adjust-hue(#811, 45)').asColor(136, 106, 17)
  itParses('adjust-hue(#811, -45)').asColor(136, 17, 106)
  itParses('adjust-hue($c, $r)').asInvalid()
  itParses('adjust-hue($c, $r)').withContext({
    '$c': asColor 'hsv($h, $s, $v)'
    '$r': '1'
  }).asInvalid()
  itParses('adjust-hue($c, $r)').withContext({
    '$c': asColor '#811'
    '$r': '-45deg'
  }).asColor(136, 17, 106)
  itParses('adjust-hue($a, $r)').withContext({
    '$a': asColor 'rgba($c, 0.5)'
    '$c': asColor '#811'
    '$r': '-45deg'
  }).asColor(136, 17, 106, 0.5)

  itParses('mix(rgb(255,0,0), blue)').asColor(127, 0, 127)
  itParses('mix(red, rgb(0,0,255), 25%)').asColor(63, 0, 191)
  itParses('mix(#ff0000, 0x0000ff)').asColor('#7f007f')
  itParses('mix(#ff0000, 0x0000ff, 25%)').asColor('#3f00bf')
  itParses('mix(red, rgb(0,0,255), 25)').asColor(63, 0, 191)
  itParses('mix($a, $b, $r)').asInvalid()
  itParses('mix($a, $b, $r)').withContext({
    '$a': asColor 'hsv($h, $s, $v)'
    '$b': asColor 'blue'
    '$r': '25%'
  }).asInvalid()
  itParses('mix($a, $b, $r)').withContext({
    '$a': asColor 'blue'
    '$b': asColor 'hsv($h, $s, $v)'
    '$r': '25%'
  }).asInvalid()
  itParses('mix($a, $b, $r)').withContext({
    '$a': asColor 'red'
    '$b': asColor 'blue'
    '$r': '25%'
  }).asColor(63, 0, 191)
  itParses('mix($c, $d, $r)').withContext({
    '$a': asColor 'red'
    '$b': asColor 'blue'
    '$c': asColor 'rgba($a, 1)'
    '$d': asColor 'rgba($b, 1)'
    '$r': '25%'
  }).asColor(63, 0, 191)

  describe 'stylus and less', ->
    beforeEach -> @scope = 'styl'

    itParses('tint(#fd0cc7,66%)').asColor(254, 172, 235)
    itParses('tint(#fd0cc7,66)').asColor(254, 172, 235)
    itParses('tint($c,$r)').asInvalid()
    itParses('tint($c, $r)').withContext({
      '$c': asColor 'hsv($h, $s, $v)'
      '$r': '1'
    }).asInvalid()
    itParses('tint($c,$r)').withContext({
      '$c': asColor '#fd0cc7'
      '$r': '66%'
    }).asColor(254, 172, 235)
    itParses('tint($c,$r)').withContext({
      '$a': asColor '#fd0cc7'
      '$c': asColor 'rgba($a, 0.9)'
      '$r': '66%'
    }).asColor(254, 172, 235, 0.966)

    itParses('shade(#fd0cc7,66%)').asColor(86, 4, 67)
    itParses('shade(#fd0cc7,66)').asColor(86, 4, 67)
    itParses('shade($c,$r)').asInvalid()
    itParses('shade($c, $r)').withContext({
      '$c': asColor 'hsv($h, $s, $v)'
      '$r': '1'
    }).asInvalid()
    itParses('shade($c,$r)').withContext({
      '$c': asColor '#fd0cc7'
      '$r': '66%'
    }).asColor(86, 4, 67)
    itParses('shade($c,$r)').withContext({
      '$a': asColor '#fd0cc7'
      '$c': asColor 'rgba($a, 0.9)'
      '$r': '66%'
    }).asColor(86, 4, 67, 0.966)

  describe 'scss and sass', ->
    beforeEach -> @scope = 'sass'

    itParses('tint(#BADA55, 42%)').asColor('#e2efb7')
    itParses('tint(#BADA55, 42)').asColor('#e2efb7')
    itParses('tint($c,$r)').asInvalid()
    itParses('tint($c, $r)').withContext({
      '$c': asColor 'hsv($h, $s, $v)'
      '$r': '1'
    }).asInvalid()
    itParses('tint($c,$r)').withContext({
      '$c': asColor '#BADA55'
      '$r': '42%'
    }).asColor('#e2efb7')
    itParses('tint($c,$r)').withContext({
      '$a': asColor '#BADA55'
      '$c': asColor 'rgba($a, 0.9)'
      '$r': '42%'
    }).asColor(226,239,183,0.942)

    itParses('shade(#663399, 42%)').asColor('#2a1540')
    itParses('shade(#663399, 42)').asColor('#2a1540')
    itParses('shade($c,$r)').asInvalid()
    itParses('shade($c, $r)').withContext({
      '$c': asColor 'hsv($h, $s, $v)'
      '$r': '1'
    }).asInvalid()
    itParses('shade($c,$r)').withContext({
      '$c': asColor '#663399'
      '$r': '42%'
    }).asColor('#2a1540')
    itParses('shade($c,$r)').withContext({
      '$a': asColor '#663399'
      '$c': asColor 'rgba($a, 0.9)'
      '$r': '42%'
    }).asColor(0x2a,0x15,0x40,0.942)

  itParses('color(#fd0cc7 tint(66%))').asColor(254, 172, 236)
  itParses('color(var(--foo) tint(66%))').withContext({
    'var(--foo)': asColor '#fd0cc7'
  }).asColor(254, 172, 236)

  itParses('adjust-color(#102030, $red: -5, $blue: 5)', 11, 32, 53)
  itParses('adjust-color(hsl(25, 100%, 80%), $lightness: -30%, $alpha: -0.4)', 255, 106, 0, 0.6)
  itParses('adjust-color($c, $red: $a, $blue: $b)').asInvalid()
  itParses('adjust-color($d, $red: $a, $blue: $b)').withContext({
    '$a': '-5'
    '$b': '5'
    '$d': asColor 'rgba($c, 1)'
  }).asInvalid()
  itParses('adjust-color($c, $red: $a, $blue: $b)').withContext({
    '$a': '-5'
    '$b': '5'
    '$c': asColor '#102030'
  }).asColor(11, 32, 53)
  itParses('adjust-color($d, $red: $a, $blue: $b)').withContext({
    '$a': '-5'
    '$b': '5'
    '$c': asColor '#102030'
    '$d': asColor 'rgba($c, 1)'
  }).asColor(11, 32, 53)

  itParses('scale-color(rgb(200, 150, 170), $green: -40%, $blue: 70%)').asColor(200, 90, 230)
  itParses('change-color(rgb(200, 150, 170), $green: 40, $blue: 70)').asColor(200, 40, 70)
  itParses('scale-color($c, $green: $a, $blue: $b)').asInvalid()
  itParses('scale-color($d, $green: $a, $blue: $b)').withContext({
    '$a': '-40%'
    '$b': '70%'
    '$d': asColor 'rgba($c, 1)'
  }).asInvalid()
  itParses('scale-color($c, $green: $a, $blue: $b)').withContext({
    '$a': '-40%'
    '$b': '70%'
    '$c': asColor 'rgb(200, 150, 170)'
  }).asColor(200, 90, 230)
  itParses('scale-color($d, $green: $a, $blue: $b)').withContext({
    '$a': '-40%'
    '$b': '70%'
    '$c': asColor 'rgb(200, 150, 170)'
    '$d': asColor 'rgba($c, 1)'
  }).asColor(200, 90, 230)

  itParses('spin(#F00, 120)').asColor(0, 255, 0)
  itParses('spin(#F00, 120)').asColor(0, 255, 0)
  itParses('spin(#F00, 120deg)').asColor(0, 255, 0)
  itParses('spin(#F00, -120)').asColor(0, 0, 255)
  itParses('spin(#F00, -120deg)').asColor(0, 0, 255)
  itParses('spin(@c, @a)').withContext({
    '@c': asColor '#F00'
    '@a': '120'
  }).asColor(0, 255, 0)
  itParses('spin(@c, @a)').withContext({
    '@a': '120'
  }).asInvalid()
  itParses('spin(@c, @a)').withContext({
    '@a': '120'
  }).asInvalid()
  itParses('spin(@c, @a,)').asUndefined()

  itParses('fade(#F00, 0.5)').asColor(255, 0, 0, 0.5)
  itParses('fade(#F00, 50%)').asColor(255, 0, 0, 0.5)
  itParses('fade(#F00, 50)').asColor(255, 0, 0, 0.5)
  itParses('fade(@c, @a)').withContext({
    '@c': asColor '#F00'
    '@a': '0.5'
  }).asColor(255, 0, 0, 0.5)
  itParses('fade(@c, @a)').withContext({
    '@a': '0.5'
  }).asInvalid()
  itParses('fade(@c, @a)').withContext({
    '@a': '0.5'
  }).asInvalid()
  itParses('fade(@c, @a,)').asUndefined()

  itParses('contrast(#bbbbbb)').asColor(0,0,0)
  itParses('contrast(#333333)').asColor(255,255,255)
  itParses('contrast(#bbbbbb, rgb(20,20,20))').asColor(20,20,20)
  itParses('contrast(#333333, rgb(20,20,20), rgb(140,140,140))').asColor(140,140,140)
  itParses('contrast(#666666, rgb(20,20,20), rgb(140,140,140), 13%)').asColor(140,140,140)

  itParses('contrast(@base)').withContext({
    '@base': asColor '#bbbbbb'
  }).asColor(0,0,0)
  itParses('contrast(@base)').withContext({
    '@base': asColor '#333333'
  }).asColor(255,255,255)
  itParses('contrast(@base, @dark)').withContext({
    '@base': asColor '#bbbbbb'
    '@dark': asColor 'rgb(20,20,20)'
  }).asColor(20,20,20)
  itParses('contrast(@base, @dark, @light)').withContext({
    '@base': asColor '#333333'
    '@dark': asColor 'rgb(20,20,20)'
    '@light': asColor 'rgb(140,140,140)'
  }).asColor(140,140,140)
  itParses('contrast(@base, @dark, @light, @threshold)').withContext({
    '@base': asColor '#666666'
    '@dark': asColor 'rgb(20,20,20)'
    '@light': asColor 'rgb(140,140,140)'
    '@threshold': '13%'
  }).asColor(140,140,140)

  itParses('contrast(@base)').asInvalid()
  itParses('contrast(@base)').asInvalid()
  itParses('contrast(@base, @dark)').asInvalid()
  itParses('contrast(@base, @dark, @light)').asInvalid()
  itParses('contrast(@base, @dark, @light, @threshold)').asInvalid()

  itParses('multiply(#ff6600, 0x666666)').asColor('#662900')
  itParses('multiply(@base, @modifier)').withContext({
    '@base': asColor '#ff6600'
    '@modifier': asColor '#666666'
  }).asColor('#662900')
  itParses('multiply(@base, @modifier)').asInvalid()

  itParses('screen(#ff6600, 0x666666)').asColor('#ffa366')
  itParses('screen(@base, @modifier)').withContext({
    '@base': asColor '#ff6600'
    '@modifier': asColor '#666666'
  }).asColor('#ffa366')
  itParses('screen(@base, @modifier)').asInvalid()

  itParses('overlay(#ff6600, 0x666666)').asColor('#ff5200')
  itParses('overlay(@base, @modifier)').withContext({
    '@base': asColor '#ff6600'
    '@modifier': asColor '#666666'
  }).asColor('#ff5200')
  itParses('overlay(@base, @modifier)').asInvalid()

  itParses('softlight(#ff6600, 0x666666)').asColor('#ff5a00')
  itParses('softlight(@base, @modifier)').withContext({
    '@base': asColor '#ff6600'
    '@modifier': asColor '#666666'
  }).asColor('#ff5a00')
  itParses('softlight(@base, @modifier)').asInvalid()

  itParses('hardlight(#ff6600, 0x666666)').asColor('#cc5200')
  itParses('hardlight(@base, @modifier)').withContext({
    '@base': asColor '#ff6600'
    '@modifier': asColor '#666666'
  }).asColor('#cc5200')
  itParses('hardlight(@base, @modifier)').asInvalid()

  itParses('difference(#ff6600, 0x666666)').asColor('#990066')
  itParses('difference(#ff6600,)()').asInvalid()
  itParses('difference(@base, @modifier)').withContext({
    '@base': asColor '#ff6600'
    '@modifier': asColor '#666666'
  }).asColor('#990066')
  itParses('difference(@base, @modifier)').asInvalid()

  itParses('exclusion(#ff6600, 0x666666)').asColor('#997a66')
  itParses('exclusion(@base, @modifier)').withContext({
    '@base': asColor '#ff6600'
    '@modifier': asColor '#666666'
  }).asColor('#997a66')
  itParses('exclusion(@base, @modifier)').asInvalid()

  itParses('average(#ff6600, 0x666666)').asColor('#b36633')
  itParses('average(@base, @modifier)').withContext({
    '@base': asColor '#ff6600'
    '@modifier': asColor '#666666'
  }).asColor('#b36633')
  itParses('average(@base, @modifier)').asInvalid()

  itParses('negation(#ff6600, 0x666666)').asColor('#99cc66')
  itParses('negation(@base, @modifier)').withContext({
    '@base': asColor '#ff6600'
    '@modifier': asColor '#666666'
  }).asColor('#99cc66')
  itParses('negation(@base, @modifier)').asInvalid()

  itParses('blend(rgba(#FFDE00,.42), 0x19C261)').asColor('#7ace38')
  itParses('blend(@top, @bottom)').withContext({
    '@top': asColor 'rgba(#FFDE00,.42)'
    '@bottom': asColor '0x19C261'
  }).asColor('#7ace38')
  itParses('blend(@top, @bottom)').asInvalid()

  itParses('complement(red)').asColor('#00ffff')
  itParses('complement(@base)').withContext({
    '@base': asColor 'red'
  }).asColor('#00ffff')
  itParses('complement(@base)').asInvalid()

  itParses('transparentify(#808080)').asColor(0,0,0,0.5)
  itParses('transparentify(#414141, black)').asColor(255,255,255,0.25)
  itParses('transparentify(#91974C, 0xF34949, 0.5)').asColor(47,229,79,0.5)
  itParses('transparentify(a)').withContext({
    'a': asColor '#808080'
  }).asColor(0,0,0,0.5)
  itParses('transparentify(a, b, 0.5)').withContext({
    'a': asColor '#91974C'
    'b': asColor '#F34949'
  }).asColor(47,229,79,0.5)
  itParses('transparentify(a)').asInvalid()

  itParses('red(#000, 255)').asColor(255,0,0)
  itParses('red(a, b)').withContext({
    'a': asColor '#000'
    'b': '255'
  }).asColor(255,0,0)
  itParses('red(a, b)').asInvalid()

  itParses('green(#000, 255)').asColor(0,255,0)
  itParses('green(a, b)').withContext({
    'a': asColor '#000'
    'b': '255'
  }).asColor(0,255,0)
  itParses('green(a, b)').asInvalid()

  itParses('blue(#000, 255)').asColor(0,0,255)
  itParses('blue(a, b)').withContext({
    'a': asColor '#000'
    'b': '255'
  }).asColor(0,0,255)
  itParses('blue(a, b)').asInvalid()

  itParses('alpha(#000, 0.5)').asColor(0,0,0,0.5)
  itParses('alpha(a, b)').withContext({
    'a': asColor '#000'
    'b': '0.5'
  }).asColor(0,0,0,0.5)
  itParses('alpha(a, b)').asInvalid()

  itParses('hue(#00c, 90deg)').asColor(0x66,0xCC,0)
  itParses('hue(a, b)').withContext({
    'a': asColor '#00c'
    'b': '90deg'
  }).asColor(0x66,0xCC,0)
  itParses('hue(a, b)').asInvalid()

  itParses('saturation(#00c, 50%)').asColor(0x33,0x33,0x99)
  itParses('saturation(a, b)').withContext({
    'a': asColor '#00c'
    'b': '50%'
  }).asColor(0x33,0x33,0x99)
  itParses('saturation(a, b)').asInvalid()

  itParses('lightness(#00c, 80%)').asColor(0x99,0x99,0xff)
  itParses('lightness(a, b)').withContext({
    'a': asColor '#00c'
    'b': '80%'
  }).asColor(0x99,0x99,0xff)
  itParses('lightness(a, b)').asInvalid()

  describe 'lua color', ->
    beforeEach -> @scope = 'lua'

    itParses('Color(255, 0, 0, 255)').asColor(255,0,0)
    itParses('Color(r, g, b, a)').withContext({
      'r': '255'
      'g': '0'
      'b': '0'
      'a': '255'
    }).asColor(255,0,0)
    itParses('Color(r, g, b, a)').asInvalid()

  #    ######## ##       ##     ##
  #    ##       ##       ###   ###
  #    ##       ##       #### ####
  #    ######   ##       ## ### ##
  #    ##       ##       ##     ##
  #    ##       ##       ##     ##
  #    ######## ######## ##     ##

  describe 'elm-lang support', ->
    beforeEach -> @scope = 'elm'

    itParses('rgba 255 0 0 1').asColor(255,0,0)
    itParses('rgba r g b a').withContext({
      'r': '255'
      'g': '0'
      'b': '0'
      'a': '1'
    }).asColor(255,0,0)
    itParses('rgba r g b a').asInvalid()

    itParses('rgb 255 0 0').asColor(255,0,0)
    itParses('rgb r g b').withContext({
      'r': '255'
      'g': '0'
      'b': '0'
    }).asColor(255,0,0)
    itParses('rgb r g b').asInvalid()

    itParses('hsla (degrees 200) 50 50 0.5').asColor(64, 149, 191, 0.5)
    itParses('hsla (degrees h) s l a').withContext({
      'h': '200'
      's': '50'
      'l': '50'
      'a': '0.5'
    }).asColor(64, 149, 191, 0.5)
    itParses('hsla (degrees h) s l a').asInvalid()

    itParses('hsla 3.49 50 50 0.5').asColor(64, 149, 191, 0.5)
    itParses('hsla h s l a').withContext({
      'h': '3.49'
      's': '50'
      'l': '50'
      'a': '0.5'
    }).asColor(64, 149, 191, 0.5)
    itParses('hsla h s l a').asInvalid()

    itParses('hsl (degrees 200) 50 50').asColor(64, 149, 191)
    itParses('hsl (degrees h) s l').withContext({
      'h': '200'
      's': '50'
      'l': '50'
    }).asColor(64, 149, 191)
    itParses('hsl (degrees h) s l').asInvalid()

    itParses('hsl 3.49 50 50').asColor(64, 149, 191)
    itParses('hsl h s l').withContext({
      'h': '3.49'
      's': '50'
      'l': '50'
    }).asColor(64, 149, 191)
    itParses('hsl h s l').asInvalid()

    itParses('grayscale 1').asColor(0, 0, 0)
    itParses('greyscale 0.5').asColor(127, 127, 127)
    itParses('grayscale 0').asColor(255, 255, 255)
    itParses('grayscale g').withContext({
      'g': '0.5'
    }).asColor(127, 127, 127)
    itParses('grayscale g').asInvalid()

    itParses('complement rgb 255 0 0').asColor('#00ffff')
    itParses('complement base').withContext({
      'base': asColor 'red'
    }).asColor('#00ffff')
    itParses('complement base').asInvalid()

  #    ##          ###    ######## ######## ##     ##
  #    ##         ## ##      ##    ##        ##   ##
  #    ##        ##   ##     ##    ##         ## ##
  #    ##       ##     ##    ##    ######      ###
  #    ##       #########    ##    ##         ## ##
  #    ##       ##     ##    ##    ##        ##   ##
  #    ######## ##     ##    ##    ######## ##     ##

  describe 'latex support', ->
    beforeEach -> @scope = 'tex'

    itParses('[gray]{1}').asColor('#ffffff')
    itParses('[rgb]{1,0.5,0}').asColor('#ff7f00')
    itParses('[RGB]{255,127,0}').asColor('#ff7f00')
    itParses('[cmyk]{0,0.5,1,0}').asColor('#ff7f00')
    itParses('[HTML]{ff7f00}').asColor('#ff7f00')
    itParses('{blue}').asColor('#0000ff')

    itParses('{blue!20}').asColor('#ccccff')
    itParses('{blue!20!black}').asColor('#000033')
    itParses('{blue!20!black!30!green}').asColor('#00590f')
