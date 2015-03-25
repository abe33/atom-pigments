cssColor = require 'css-color-function'

{
  int
  float
  percent
  intOrPercent
  floatOrPercent
  comma
  notQuote
  hexa
  ps
  pe
  variables
  namePrefixes
} = require './regexes'

{
  strip
  split
  clamp
  clampInt
} = require './utils'

ExpressionsRegistry = require './expressions-registry'
ColorExpression = require './color-expression'
SVGColors = require './svg-colors'
Color = require './color'

MAX_PER_COMPONENT =
  red: 255
  green: 255
  blue: 255
  alpha: 1
  hue: 360
  saturation: 100
  lightness: 100

mixColors = (color1, color2, amount=0.5) ->
  inverse = 1 - amount
  color = new Color

  color.rgba = [
    Math.floor(color1.red * amount) + Math.floor(color2.red * inverse)
    Math.floor(color1.green * amount) + Math.floor(color2.green * inverse)
    Math.floor(color1.blue * amount) + Math.floor(color2.blue * inverse)
    color1.alpha * amount + color2.alpha * inverse
  ]

  color

readParam = (param, block) ->
  re = ///\$(\w+):\s*((-?#{float})|#{variables})///
  if re.test(param)
    [_, name, value] = re.exec(param)

    block(name, value)

module.exports = getRegistry: (context) ->
  registry = new ExpressionsRegistry(ColorExpression)

  ##    ##       #### ######## ######## ########     ###    ##
  ##    ##        ##     ##    ##       ##     ##   ## ##   ##
  ##    ##        ##     ##    ##       ##     ##  ##   ##  ##
  ##    ##        ##     ##    ######   ########  ##     ## ##
  ##    ##        ##     ##    ##       ##   ##   ######### ##
  ##    ##        ##     ##    ##       ##    ##  ##     ## ##
  ##    ######## ####    ##    ######## ##     ## ##     ## ########

  # #6f3489ef
  registry.createExpression 'css_hexa_8', "#(#{hexa}{8})(?![\\d\\w])", (match, expression, context) ->
    [_, hexa] = match

    @hexARGB = hexa

  # #3489ef
  registry.createExpression 'css_hexa_6', "#(#{hexa}{6})(?![\\d\\w])", (match, expression, context) ->
    [_, hexa] = match

    @hex = hexa

  # #38e
  registry.createExpression 'css_hexa_3', "#(#{hexa}{3})(?![\\d\\w])", (match, expression, context) ->
    [_, hexa] = match
    colorAsInt = context.readInt(hexa, 16)

    @red = (colorAsInt >> 8 & 0xf) * 17
    @green = (colorAsInt >> 4 & 0xf) * 17
    @blue = (colorAsInt & 0xf) * 17

  # 0xab3489ef
  registry.createExpression 'int_hexa_8', "0x(#{hexa}{8})(?!#{hexa})", (match, expression, context) ->
    [_, hexa] = match

    @hexARGB = hexa

  # 0x3489ef
  registry.createExpression 'int_hexa_6', "0x(#{hexa}{6})(?!#{hexa})", (match, expression, context) ->
    [_, hexa] = match

    @hex = hexa

  # rgb(50,120,200)
  registry.createExpression 'css_rgb', strip("
    rgb#{ps}\\s*
      (#{intOrPercent}|#{variables})
      #{comma}
      (#{intOrPercent}|#{variables})
      #{comma}
      (#{intOrPercent}|#{variables})
    #{pe}
  "), (match, expression, context) ->
    [_,r,_,_,g,_,_,b] = match

    @red = context.readIntOrPercent(r)
    @green = context.readIntOrPercent(g)
    @blue = context.readIntOrPercent(b)
    @alpha = 1

  # rgba(50,120,200,0.7)
  registry.createExpression 'css_rgba', strip("
    rgba#{ps}\\s*
      (#{intOrPercent}|#{variables})
      #{comma}
      (#{intOrPercent}|#{variables})
      #{comma}
      (#{intOrPercent}|#{variables})
      #{comma}
      (#{float}|#{variables})
    #{pe}
  "), (match, expression, context) ->
    [_,r,_,_,g,_,_,b,_,_,a] = match

    @red = context.readIntOrPercent(r)
    @green = context.readIntOrPercent(g)
    @blue = context.readIntOrPercent(b)
    @alpha = context.readFloat(a)

  # rgba(green,0.7)
  registry.createExpression 'stylus_rgba', strip("
    rgba#{ps}\\s*
      (#{notQuote})
      #{comma}
      (#{float}|#{variables})
    #{pe}
  "), (match, expression, context) ->
    [_,subexpr,a] = match

    baseColor = context.readColor(subexpr)

    return @invalid = true unless baseColor?

    @rgb = baseColor.rgb
    @alpha = context.readFloat(a)

  # hsl(210,50%,50%)
  registry.createExpression 'css_hsl', strip("
    hsl#{ps}\\s*
      (#{int}|#{variables})
      #{comma}
      (#{percent}|#{variables})
      #{comma}
      (#{percent}|#{variables})
    #{pe}
  "), (match, expression, context) ->
    [_,h,_,s,_,l] = match

    @hsl = [
      context.readInt(h)
      context.readFloat(s)
      context.readFloat(l)
    ]
    @alpha = 1

  # hsla(210,50%,50%,0.7)
  registry.createExpression 'css_hsla', strip("
    hsla#{ps}\\s*
      (#{int}|#{variables})
      #{comma}
      (#{percent}|#{variables})
      #{comma}
      (#{percent}|#{variables})
      #{comma}
      (#{float}|#{variables})
    #{pe}
  "), (match, expression, context) ->
    [_,h,_,s,_,l,_,a] = match

    @hsl = [
      context.readInt(h)
      context.readFloat(s)
      context.readFloat(l)
    ]
    @alpha = context.readFloat(a)

  # hsv(210,70%,90%)
  registry.createExpression 'hsv', strip("
    hsv#{ps}\\s*
      (#{int}|#{variables})
      #{comma}
      (#{percent}|#{variables})
      #{comma}
      (#{percent}|#{variables})
    #{pe}
  "), (match, expression, context) ->
    [_,h,_,s,_,v] = match

    @hsv = [
      context.readInt(h)
      context.readFloat(s)
      context.readFloat(v)
    ]
    @alpha = 1

  # hsva(210,70%,90%,0.7)
  registry.createExpression 'hsva', strip("
    hsva#{ps}\\s*
      (#{int}|#{variables})
      #{comma}
      (#{percent}|#{variables})
      #{comma}
      (#{percent}|#{variables})
      #{comma}
      (#{float}|#{variables})
    #{pe}
  "), (match, expression, context) ->
    [_,h,_,s,_,v,_,a] = match

    @hsv = [
      context.readInt(h)
      context.readFloat(s)
      context.readFloat(v)
    ]
    @alpha = context.readFloat(a)

  # vec4(0.2, 0.5, 0.9, 0.7)
  registry.createExpression 'vec4', strip("
    vec4#{ps}\\s*
      (#{float})
      #{comma}
      (#{float})
      #{comma}
      (#{float})
      #{comma}
      (#{float})
    #{pe}
  "), (match, expression, context) ->
    [_,h,s,l,a] = match

    @rgba = [
      context.readFloat(h) * 255
      context.readFloat(s) * 255
      context.readFloat(l) * 255
      context.readFloat(a)
    ]

  # hwb(210,40%,40%)
  registry.createExpression 'hwb', strip("
    hwb#{ps}\\s*
      (#{int}|#{variables})
      #{comma}
      (#{percent}|#{variables})
      #{comma}
      (#{percent}|#{variables})
      (#{comma}(#{float}|#{variables}))?
    #{pe}
  "), (match, expression, context) ->
    [_,h,_,w,_,b,_,_,a] = match

    @hwb = [
      context.readInt(h)
      context.readFloat(w)
      context.readFloat(b)
    ]
    @alpha = if a? then context.readFloat(a) else 1

  # gray(50%)
  # The priority is set to 1 to make sure that it appears before named colors
  registry.createExpression 'gray', strip("
    gray#{ps}\\s*
      (#{percent}|#{variables})
      (#{comma}(#{float}|#{variables}))?
    #{pe}"), 1, (match, expression, context) ->

    [_,p,_,_,a] = match

    p = context.readFloat(p) / 100 * 255
    @rgb = [p, p, p]
    @alpha = if a? then context.readFloat(a) else 1

  # dodgerblue
  colors = Object.keys(SVGColors.allCases)
  colorRegexp = "(#{namePrefixes})(#{colors.join('|')})(?!\\s*[-\\.:=\\(])\\b"

  registry.createExpression 'named_colors', colorRegexp, (match, expression, context) ->
    [_,_,name] = match

    @colorExpression = @name = name
    @hex = SVGColors.allCases[name].replace('#','')

  ##    ######## ##     ## ##    ##  ######
  ##    ##       ##     ## ###   ## ##    ##
  ##    ##       ##     ## ####  ## ##
  ##    ######   ##     ## ## ## ## ##
  ##    ##       ##     ## ##  #### ##
  ##    ##       ##     ## ##   ### ##    ##
  ##    ##        #######  ##    ##  ######

  # darken(#666666, 20%)
  registry.createExpression 'darken', strip("
    darken#{ps}
      (#{notQuote})
      #{comma}
      (#{percent}|#{variables})
    #{pe}
  "), (match, expression, context) ->
    [_, subexpr, amount] = match

    amount = context.readFloat(amount)
    baseColor = context.readColor(subexpr)

    return @invalid = true unless baseColor?

    [h,s,l] = baseColor.hsl

    @hsl = [h, s, clampInt(l - amount)]
    @alpha = baseColor.alpha

  # lighten(#666666, 20%)
  registry.createExpression 'lighten', strip("
    lighten#{ps}
      (#{notQuote})
      #{comma}
      (#{percent}|#{variables})
    #{pe}
  "), (match, expression, context) ->
    [_, subexpr, amount] = match

    amount = context.readFloat(amount)
    baseColor = context.readColor(subexpr)

    return @invalid = true unless baseColor?

    [h,s,l] = baseColor.hsl

    @hsl = [h, s, clampInt(l + amount)]
    @alpha = baseColor.alpha

  # transparentize(#ffffff, 0.5)
  # transparentize(#ffffff, 50%)
  # fadein(#ffffff, 0.5)
  registry.createExpression 'transparentize', strip("
    (transparentize|fadein)#{ps}
      (#{notQuote})
      #{comma}
      (#{floatOrPercent}|#{variables})
    #{pe}
  "), (match, expression, context) ->
    [_, _, subexpr, amount] = match

    amount = context.readFloatOrPercent(amount)
    baseColor = context.readColor(subexpr)

    return @invalid = true unless baseColor?

    @rgb = baseColor.rgb
    @alpha = clamp(baseColor.alpha - amount)

  # opacify(0x78ffffff, 0.5)
  # opacify(0x78ffffff, 50%)
  # fadeout(0x78ffffff, 0.5)
  registry.createExpression 'opacify', strip("
    (opacify|fadeout)#{ps}
      (#{notQuote})
      #{comma}
      (#{floatOrPercent}|#{variables})
    #{pe}
  "), (match, expression, context) ->
    [_, _, subexpr, amount] = match

    amount = context.readFloatOrPercent(amount)
    baseColor = context.readColor(subexpr)

    return @invalid = true unless baseColor?

    @rgb = baseColor.rgb
    @alpha = clamp(baseColor.alpha + amount)

  # adjust-hue(#855, 60deg)
  registry.createExpression 'adjust-hue', strip("
    adjust-hue#{ps}
      (#{notQuote})
      #{comma}
      (-?#{int}deg|#{variables}|-?#{percent})
    #{pe}
  "), (match, expression, context) ->
    [_, subexpr, amount] = match

    amount = context.readFloat(amount)
    baseColor = context.readColor(subexpr)

    return @invalid = true unless baseColor?

    [h,s,l] = baseColor.hsl

    @hsl = [(h + amount) % 360, s, l]
    @alpha = baseColor.alpha

  # mix(#f00, #00F, 25%)
  # mix(#f00, #00F)
  registry.createExpression 'mix', strip("
    mix#{ps}
      (
        (#{notQuote})
        #{comma}
        (#{notQuote})
        #{comma}
        (#{floatOrPercent}|#{variables})
      |
        (#{notQuote})
        #{comma}
        (#{notQuote})
      )
    #{pe}
  "), (match, expression, context) ->
    [_, _, color1A, color2A, amount, _, _, color1B, color2B] = match

    if color1A?
      color1 = color1A
      color2 = color2A
      amount = context.readFloatOrPercent(amount)
    else
      color1 = color1B
      color2 = color2B
      amount = 0.5


    baseColor1 = context.readColor(color1)
    baseColor2 = context.readColor(color2)

    return @invalid = true unless baseColor1? and baseColor2?

    @rgba = mixColors(baseColor1, baseColor2, amount).rgba

  # tint(red, 50%)
  registry.createExpression 'tint', strip("
    tint#{ps}
      (#{notQuote})
      #{comma}
      (#{floatOrPercent}|#{variables})
    #{pe}
  "), (match, expression, context) ->
    [_, subexpr, amount] = match

    amount = context.readFloatOrPercent(amount)
    baseColor = context.readColor(subexpr)

    return @invalid = true unless baseColor?

    white = new Color(255, 255, 255)

    @rgba = mixColors(white, baseColor, amount).rgba

  # shade(red, 50%)
  registry.createExpression 'shade', strip("
    shade#{ps}
      (#{notQuote})
      #{comma}
      (#{floatOrPercent}|#{variables})
    #{pe}
  "), (match, expression, context) ->
    [_, subexpr, amount] = match

    amount = context.readFloatOrPercent(amount)
    baseColor = context.readColor(subexpr)

    return @invalid = true unless baseColor?

    black = new Color(0,0,0)

    @rgba = mixColors(black, baseColor, amount).rgba

  # desaturate(#855, 20%)
  # desaturate(#855, 0.2)
  registry.createExpression 'desaturate', "desaturate#{ps}(#{notQuote})#{comma}(#{floatOrPercent}|#{variables})#{pe}", (match, expression, context) ->
    [_, subexpr, amount] = match

    amount = context.readFloatOrPercent(amount)
    baseColor = context.readColor(subexpr)

    return @invalid = true unless baseColor?

    [h,s,l] = baseColor.hsl

    @hsl = [h, clampInt(s - amount * 100), l]
    @alpha = baseColor.alpha

  # saturate(#855, 20%)
  # saturate(#855, 0.2)
  registry.createExpression 'saturate', strip("
    saturate#{ps}
      (#{notQuote})
      #{comma}
      (#{floatOrPercent}|#{variables})
    #{pe}
  "), (match, expression, context) ->
    [_, subexpr, amount] = match

    amount = context.readFloatOrPercent(amount)
    baseColor = context.readColor(subexpr)

    return @invalid = true unless baseColor?

    [h,s,l] = baseColor.hsl

    @hsl = [h, clampInt(s + amount * 100), l]
    @alpha = baseColor.alpha

  # grayscale(red)
  # greyscale(red)
  registry.createExpression 'grayscale', "gr(a|e)yscale#{ps}(#{notQuote})#{pe}", (match, expression, context) ->
    [_, _, subexpr] = match

    baseColor = context.readColor(subexpr)

    return @invalid = true unless baseColor?

    [h,s,l] = baseColor.hsl

    @hsl = [h, 0, l]
    @alpha = baseColor.alpha

  # invert(green)
  registry.createExpression 'invert', "invert#{ps}(#{notQuote})#{pe}", (match, expression, context) ->
    [_, subexpr] = match

    baseColor = context.readColor(subexpr)

    return @invalid = true unless baseColor?

    [r,g,b] = baseColor.rgb

    @rgb = [255 - r, 255 - g, 255 - b]
    @alpha = baseColor.alpha

  # color(green tint(50%))
  registry.createExpression 'css_color_function', "color#{ps}(#{notQuote})#{pe}", (match, expression, context) ->
    try
      rgba = cssColor.convert(expression)
      @rgba = context.readColor(rgba).rgba
    catch e
      @invalid = true

  # adjust-color(red, $lightness: 30%)
  registry.createExpression 'sass_adjust_color', "adjust-color#{ps}(#{notQuote})#{pe}", 1, (match, expression, context) ->
    [_, subexpr] = match
    [subject, params...] = split(subexpr)

    baseColor = context.readColor(subject)

    return @invalid = true unless baseColor?

    for param in params
      readParam param, (name, value) ->
        baseColor[name] += context.readFloat(value)

    @rgba = baseColor.rgba

  # scale-color(red, $lightness: 30%)
  registry.createExpression 'sass_scale_color', "scale-color#{ps}(#{notQuote})#{pe}", 1, (match, expression, context) ->

    [_, subexpr] = match
    [subject, params...] = split(subexpr)

    baseColor = context.readColor(subject)

    return @invalid = true unless baseColor?

    for param in params
      readParam param, (name, value) ->
        value = context.readFloat(value) / 100

        result = if value > 0
          dif = MAX_PER_COMPONENT[name] - baseColor[name]
          result = baseColor[name] + dif * value
        else
          result = baseColor[name] * (1 + value)

        baseColor[name] = result

    @rgba = baseColor.rgba

  # change-color(red, $lightness: 30%)
  registry.createExpression 'sass_change_color', "change-color#{ps}(#{notQuote})#{pe}", 1, (match, expression, context) ->
    [_, subexpr] = match
    [subject, params...] = split(subexpr)

    baseColor = context.readColor(subject)

    return @invalid = true unless baseColor?

    for param in params
      readParam param, (name, value) ->
        baseColor[name] = context.readFloat(value)

    @rgba = baseColor.rgba

  if context?.hasVariables()
    registry.addExpression(context.createVariableExpression())

  registry
