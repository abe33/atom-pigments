cssColor = require 'css-color-function'

{
  int
  float
  percent
  optionalPercent
  intOrPercent
  floatOrPercent
  comma
  notQuote
  hexadecimal
  ps
  pe
  variables
  namePrefixes
  createVariableRegExpString
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
BlendModes = require './blend-modes'

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

contrast = (base, dark=new Color('black'), light=new Color('white'), threshold=0.43) ->
  [light, dark] = [dark, light] if dark.luma > light.luma

  if base.luma > threshold
    dark
  else
    light

blendMethod = (registry, name, method) ->
  registry.createExpression name, strip("
    #{name}#{ps}
      (
        #{notQuote}
        #{comma}
        #{notQuote}
      )
    #{pe}
  "), (match, expression, context) ->
    [_, expr] = match

    [color1, color2] = split(expr)

    baseColor1 = context.readColor(color1)
    baseColor2 = context.readColor(color2)

    return @invalid = true if isInvalid(baseColor1) or isInvalid(baseColor2)

    {@rgba} = baseColor1.blend(baseColor2, method)


readParam = (param, block) ->
  re = ///\$(\w+):\s*((-?#{float})|#{variables})///
  if re.test(param)
    [_, name, value] = re.exec(param)

    block(name, value)

isInvalid = (color) -> not color?.isValid()

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
  registry.createExpression 'css_hexa_8', "#(#{hexadecimal}{8})(?![\\d\\w])", (match, expression, context) ->
    [_, hexa] = match

    @hexRGBA = hexa

  # #3489ef
  registry.createExpression 'css_hexa_6', "#(#{hexadecimal}{6})(?![\\d\\w])", (match, expression, context) ->
    [_, hexa] = match

    @hex = hexa

  # #6f34
  registry.createExpression 'css_hexa_4', "(#{namePrefixes})#(#{hexadecimal}{4})(?![\\d\\w])", (match, expression, context) ->
    [_, _, hexa] = match
    colorAsInt = context.readInt(hexa, 16)

    @colorExpression = "##{hexa}"
    @red = (colorAsInt >> 12 & 0xf) * 17
    @green = (colorAsInt >> 8 & 0xf) * 17
    @blue = (colorAsInt >> 4 & 0xf) * 17
    @alpha = ((colorAsInt & 0xf) * 17) / 255

  # #38e
  registry.createExpression 'css_hexa_3', "(#{namePrefixes})#(#{hexadecimal}{3})(?![\\d\\w])", (match, expression, context) ->
    [_, _, hexa] = match
    colorAsInt = context.readInt(hexa, 16)

    @colorExpression = "##{hexa}"
    @red = (colorAsInt >> 8 & 0xf) * 17
    @green = (colorAsInt >> 4 & 0xf) * 17
    @blue = (colorAsInt & 0xf) * 17

  # 0xab3489ef
  registry.createExpression 'int_hexa_8', "0x(#{hexadecimal}{8})(?!#{hexadecimal})", (match, expression, context) ->
    [_, hexa] = match

    @hexARGB = hexa

  # 0x3489ef
  registry.createExpression 'int_hexa_6', "0x(#{hexadecimal}{6})(?!#{hexadecimal})", (match, expression, context) ->
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

    return @invalid = true if isInvalid(baseColor)

    @rgb = baseColor.rgb
    @alpha = context.readFloat(a)

  # hsl(210,50%,50%)
  registry.createExpression 'css_hsl', strip("
    hsl#{ps}\\s*
      (#{int}|#{variables})
      #{comma}
      (#{optionalPercent}|#{variables})
      #{comma}
      (#{optionalPercent}|#{variables})
    #{pe}
  "), (match, expression, context) ->
    [_,h,_,s,_,l] = match

    hsl = [
      context.readInt(h)
      context.readFloat(s)
      context.readFloat(l)
    ]

    return @invalid = true if hsl.some (v) -> not v? or isNaN(v)

    @hsl = hsl
    @alpha = 1

  # hsla(210,50%,50%,0.7)
  registry.createExpression 'css_hsla', strip("
    hsla#{ps}\\s*
      (#{int}|#{variables})
      #{comma}
      (#{optionalPercent}|#{variables})
      #{comma}
      (#{optionalPercent}|#{variables})
      #{comma}
      (#{float}|#{variables})
    #{pe}
  "), (match, expression, context) ->
    [_,h,_,s,_,l,_,a] = match

    hsl = [
      context.readInt(h)
      context.readFloat(s)
      context.readFloat(l)
    ]

    return @invalid = true if hsl.some (v) -> not v? or isNaN(v)

    @hsl = hsl
    @alpha = context.readFloat(a)

  # hsv(210,70%,90%)
  registry.createExpression 'hsv', strip("
    (hsv|hsb)#{ps}\\s*
      (#{int}|#{variables})
      #{comma}
      (#{optionalPercent}|#{variables})
      #{comma}
      (#{optionalPercent}|#{variables})
    #{pe}
  "), (match, expression, context) ->
    [_,_,h,_,s,_,v] = match

    hsv = [
      context.readInt(h)
      context.readFloat(s)
      context.readFloat(v)
    ]

    return @invalid = true if hsv.some (v) -> not v? or isNaN(v)

    @hsv = hsv
    @alpha = 1

  # hsva(210,70%,90%,0.7)
  registry.createExpression 'hsva', strip("
    (hsva|hsba)#{ps}\\s*
      (#{int}|#{variables})
      #{comma}
      (#{optionalPercent}|#{variables})
      #{comma}
      (#{optionalPercent}|#{variables})
      #{comma}
      (#{float}|#{variables})
    #{pe}
  "), (match, expression, context) ->
    [_,_,h,_,s,_,v,_,a] = match

    hsv = [
      context.readInt(h)
      context.readFloat(s)
      context.readFloat(v)
    ]

    return @invalid = true if hsv.some (v) -> not v? or isNaN(v)

    @hsv = hsv
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
      (#{optionalPercent}|#{variables})
      #{comma}
      (#{optionalPercent}|#{variables})
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
      (#{optionalPercent}|#{variables})
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
      (#{optionalPercent}|#{variables})
    #{pe}
  "), (match, expression, context) ->
    [_, subexpr, amount] = match

    amount = context.readFloat(amount)
    baseColor = context.readColor(subexpr)

    return @invalid = true if isInvalid(baseColor)

    [h,s,l] = baseColor.hsl

    @hsl = [h, s, clampInt(l - amount)]
    @alpha = baseColor.alpha

  # lighten(#666666, 20%)
  registry.createExpression 'lighten', strip("
    lighten#{ps}
      (#{notQuote})
      #{comma}
      (#{optionalPercent}|#{variables})
    #{pe}
  "), (match, expression, context) ->
    [_, subexpr, amount] = match

    amount = context.readFloat(amount)
    baseColor = context.readColor(subexpr)

    return @invalid = true if isInvalid(baseColor)

    [h,s,l] = baseColor.hsl

    @hsl = [h, s, clampInt(l + amount)]
    @alpha = baseColor.alpha

  # fade(#ffffff, 0.5)
  # alpha(#ffffff, 0.5)
  registry.createExpression 'fade', strip("
    (fade|alpha)#{ps}
      (#{notQuote})
      #{comma}
      (#{floatOrPercent}|#{variables})
    #{pe}
  "), (match, expression, context) ->
    [_, _, subexpr, amount] = match

    amount = context.readFloatOrPercent(amount)
    baseColor = context.readColor(subexpr)

    return @invalid = true if isInvalid(baseColor)

    @rgb = baseColor.rgb
    @alpha = amount

  # transparentize(#ffffff, 0.5)
  # transparentize(#ffffff, 50%)
  # fadeout(#ffffff, 0.5)
  registry.createExpression 'transparentize', strip("
    (transparentize|fadeout|fade-out|fade_out)#{ps}
      (#{notQuote})
      #{comma}
      (#{floatOrPercent}|#{variables})
    #{pe}
  "), (match, expression, context) ->
    [_, _, subexpr, amount] = match

    amount = context.readFloatOrPercent(amount)
    baseColor = context.readColor(subexpr)

    return @invalid = true if isInvalid(baseColor)

    @rgb = baseColor.rgb
    @alpha = clamp(baseColor.alpha - amount)

  # opacify(0x78ffffff, 0.5)
  # opacify(0x78ffffff, 50%)
  # fadein(0x78ffffff, 0.5)
  # alpha(0x78ffffff, 0.5)
  registry.createExpression 'opacify', strip("
    (opacify|fadein|fade-in|fade_in)#{ps}
      (#{notQuote})
      #{comma}
      (#{floatOrPercent}|#{variables})
    #{pe}
  "), (match, expression, context) ->
    [_, _, subexpr, amount] = match

    amount = context.readFloatOrPercent(amount)
    baseColor = context.readColor(subexpr)

    return @invalid = true if isInvalid(baseColor)

    @rgb = baseColor.rgb
    @alpha = clamp(baseColor.alpha + amount)

  # red(#000,255)
  # green(#000,255)
  # blue(#000,255)
  registry.createExpression 'stylus_component_functions', strip("
    (red|green|blue)#{ps}
      (#{notQuote})
      #{comma}
      (#{int}|#{variables})
    #{pe}
  "), (match, expression, context) ->
    [_, channel, subexpr, amount] = match

    amount = context.readInt(amount)
    baseColor = context.readColor(subexpr)

    return @invalid = true if isInvalid(baseColor)
    return @invalid = true if isNaN(amount)

    @[channel] = amount

  # transparentify(#808080)
  registry.createExpression 'transparentify', strip("
    transparentify#{ps}
    (#{notQuote})
    #{pe}
  "), (match, expression, context) ->
    [_, expr] = match

    [top, bottom, alpha] = split(expr)

    top = context.readColor(top)
    bottom = context.readColor(bottom)
    alpha = context.readFloatOrPercent(alpha)

    return @invalid = true if isInvalid(top)
    return @invalid = true if bottom? and isInvalid(bottom)

    bottom ?= new Color(255,255,255,1)
    alpha = undefined if isNaN(alpha)

    bestAlpha = ['red','green','blue'].map((channel) ->
      res = (top[channel] - (bottom[channel])) / ((if 0 < top[channel] - (bottom[channel]) then 255 else 0) - (bottom[channel]))
      res
    ).sort((a, b) -> a < b)[0]

    processChannel = (channel) ->
      if bestAlpha is 0
        bottom[channel]
      else
        bottom[channel] + (top[channel] - (bottom[channel])) / bestAlpha

    bestAlpha = alpha if alpha?
    bestAlpha = Math.max(Math.min(bestAlpha, 1), 0)

    @red = processChannel('red')
    @green = processChannel('green')
    @blue = processChannel('blue')
    @alpha = Math.round(bestAlpha * 100) / 100

  # hue(#855, 60deg)
  registry.createExpression 'hue', strip("
    hue#{ps}
      (#{notQuote})
      #{comma}
      (#{int}deg|#{variables})
    #{pe}
  "), (match, expression, context) ->
    [_, subexpr, amount] = match

    amount = context.readFloat(amount)
    baseColor = context.readColor(subexpr)

    return @invalid = true if isInvalid(baseColor)
    return @invalid = true if isNaN(amount)

    [h,s,l] = baseColor.hsl

    @hsl = [amount % 360, s, l]
    @alpha = baseColor.alpha

  # saturation(#855, 60deg)
  # lightness(#855, 60deg)
  registry.createExpression 'stylus_sl_component_functions', strip("
    (saturation|lightness)#{ps}
      (#{notQuote})
      #{comma}
      (#{intOrPercent}|#{variables})
    #{pe}
  "), (match, expression, context) ->
    [_, channel, subexpr, amount] = match

    amount = context.readInt(amount)
    baseColor = context.readColor(subexpr)

    return @invalid = true if isInvalid(baseColor)
    return @invalid = true if isNaN(amount)

    baseColor[channel] = amount
    @rgba = baseColor.rgba

  # adjust-hue(#855, 60deg)
  registry.createExpression 'adjust-hue', strip("
    adjust-hue#{ps}
      (#{notQuote})
      #{comma}
      (-?#{int}deg|#{variables}|-?#{optionalPercent})
    #{pe}
  "), (match, expression, context) ->
    [_, subexpr, amount] = match

    amount = context.readFloat(amount)
    baseColor = context.readColor(subexpr)

    return @invalid = true if isInvalid(baseColor)

    [h,s,l] = baseColor.hsl

    @hsl = [(h + amount) % 360, s, l]
    @alpha = baseColor.alpha

  # mix(#f00, #00F, 25%)
  # mix(#f00, #00F)
  registry.createExpression 'mix', strip("
    mix#{ps}
      (
        #{notQuote}
        #{comma}
        #{notQuote}
        #{comma}
        (#{floatOrPercent}|#{variables})
      )
    #{pe}
  "), (match, expression, context) ->
    [_, expr] = match

    [color1, color2, amount] = split(expr)

    if amount?
      amount = context.readFloatOrPercent(amount)
    else
      amount = 0.5

    baseColor1 = context.readColor(color1)
    baseColor2 = context.readColor(color2)

    return @invalid = true if isInvalid(baseColor1) or isInvalid(baseColor2)

    {@rgba} = mixColors(baseColor1, baseColor2, amount)

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

    return @invalid = true if isInvalid(baseColor)

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

    return @invalid = true if isInvalid(baseColor)

    black = new Color(0,0,0)

    @rgba = mixColors(black, baseColor, amount).rgba

  # desaturate(#855, 20%)
  # desaturate(#855, 0.2)
  registry.createExpression 'desaturate', "desaturate#{ps}(#{notQuote})#{comma}(#{floatOrPercent}|#{variables})#{pe}", (match, expression, context) ->
    [_, subexpr, amount] = match

    amount = context.readFloatOrPercent(amount)
    baseColor = context.readColor(subexpr)

    return @invalid = true if isInvalid(baseColor)

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

    return @invalid = true if isInvalid(baseColor)

    [h,s,l] = baseColor.hsl

    @hsl = [h, clampInt(s + amount * 100), l]
    @alpha = baseColor.alpha

  # grayscale(red)
  # greyscale(red)
  registry.createExpression 'grayscale', "gr(a|e)yscale#{ps}(#{notQuote})#{pe}", (match, expression, context) ->
    [_, _, subexpr] = match

    baseColor = context.readColor(subexpr)

    return @invalid = true if isInvalid(baseColor)

    [h,s,l] = baseColor.hsl

    @hsl = [h, 0, l]
    @alpha = baseColor.alpha

  # invert(green)
  registry.createExpression 'invert', "invert#{ps}(#{notQuote})#{pe}", (match, expression, context) ->
    [_, subexpr] = match

    baseColor = context.readColor(subexpr)

    return @invalid = true if isInvalid(baseColor)

    [r,g,b] = baseColor.rgb

    @rgb = [255 - r, 255 - g, 255 - b]
    @alpha = baseColor.alpha

  # complement(green)
  registry.createExpression 'complement', "complement#{ps}(#{notQuote})#{pe}", (match, expression, context) ->
    [_, subexpr] = match

    baseColor = context.readColor(subexpr)

    return @invalid = true if isInvalid(baseColor)

    [h,s,l] = baseColor.hsl

    @hsl = [(h + 180) % 360, s, l]
    @alpha = baseColor.alpha

  # spin(green, 20)
  # spin(green, 20deg)
  registry.createExpression 'spin', strip("
    spin#{ps}
      (#{notQuote})
      #{comma}
      (-?(#{int})(deg)?|#{variables})
    #{pe}
  "), (match, expression, context) ->
    [_, subexpr, angle] = match

    baseColor = context.readColor(subexpr)
    angle = context.readInt(angle)

    return @invalid = true if isInvalid(baseColor)

    [h,s,l] = baseColor.hsl

    @hsl = [(360 + h + angle) % 360, s, l]
    @alpha = baseColor.alpha

  # contrast(#666666, #111111, #999999, threshold)
  registry.createExpression 'contrast_n_arguments', strip("
    contrast#{ps}
      (
        #{notQuote}
        #{comma}
        #{notQuote}
      )
    #{pe}
  "), (match, expression, context) ->
    [_, expr] = match

    [base, dark, light, threshold] = split(expr)

    baseColor = context.readColor(base)
    dark = context.readColor(dark)
    light = context.readColor(light)
    threshold = context.readPercent(threshold) if threshold?

    return @invalid = true if isInvalid(baseColor)
    return @invalid = true if dark?.invalid
    return @invalid = true if light?.invalid

    res = contrast(baseColor, dark, light)

    return @invalid = true if isInvalid(res)

    {@rgb} = contrast(baseColor, dark, light, threshold)

  # contrast(#666666)
  registry.createExpression 'contrast_1_argument', strip("
    contrast#{ps}
      (#{notQuote})
    #{pe}
  "), (match, expression, context) ->
    [_, subexpr] = match

    baseColor = context.readColor(subexpr)

    return @invalid = true if isInvalid(baseColor)

    {@rgb} = contrast(baseColor)

  # color(green tint(50%))
  registry.createExpression 'css_color_function', "(#{namePrefixes})(color#{ps}(#{notQuote})#{pe})", (match, expression, context) ->
    try
      [_,_,expr] = match
      rgba = cssColor.convert(expr)
      @rgba = context.readColor(rgba).rgba
      @colorExpression = expr
    catch e
      @invalid = true

  # adjust-color(red, $lightness: 30%)
  registry.createExpression 'sass_adjust_color', "adjust-color#{ps}(#{notQuote})#{pe}", 1, (match, expression, context) ->
    [_, subexpr] = match
    [subject, params...] = split(subexpr)

    baseColor = context.readColor(subject)

    return @invalid = true if isInvalid(baseColor)

    for param in params
      readParam param, (name, value) ->
        baseColor[name] += context.readFloat(value)

    @rgba = baseColor.rgba

  # scale-color(red, $lightness: 30%)
  registry.createExpression 'sass_scale_color', "scale-color#{ps}(#{notQuote})#{pe}", 1, (match, expression, context) ->

    [_, subexpr] = match
    [subject, params...] = split(subexpr)

    baseColor = context.readColor(subject)

    return @invalid = true if isInvalid(baseColor)

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

    return @invalid = true if isInvalid(baseColor)

    for param in params
      readParam param, (name, value) ->
        baseColor[name] = context.readFloat(value)

    @rgba = baseColor.rgba

  # blend(rgba(#FFDE00,.42), 0x19C261)
  registry.createExpression 'stylus_blend', strip("
    blend#{ps}
      (
        #{notQuote}
        #{comma}
        #{notQuote}
      )
    #{pe}
  "), (match, expression, context) ->
    [_, expr] = match

    [color1, color2] = split(expr)

    baseColor1 = context.readColor(color1)
    baseColor2 = context.readColor(color2)

    return @invalid = true if isInvalid(baseColor1) or isInvalid(baseColor2)

    @rgba = [
      baseColor1.red * baseColor1.alpha + baseColor2.red * (1 - baseColor1.alpha)
      baseColor1.green * baseColor1.alpha + baseColor2.green * (1 - baseColor1.alpha)
      baseColor1.blue * baseColor1.alpha + baseColor2.blue * (1 - baseColor1.alpha)
      baseColor1.alpha + baseColor2.alpha - baseColor1.alpha * baseColor2.alpha
    ]

  # multiply(#f00, #00F)
  blendMethod registry, 'multiply', BlendModes.MULTIPLY

  # screen(#f00, #00F)
  blendMethod registry, 'screen', BlendModes.SCREEN

  # overlay(#f00, #00F)
  blendMethod registry, 'overlay', BlendModes.OVERLAY

  # softlight(#f00, #00F)
  blendMethod registry, 'softlight', BlendModes.SOFT_LIGHT

  # hardlight(#f00, #00F)
  blendMethod registry, 'hardlight', BlendModes.HARD_LIGHT

  # difference(#f00, #00F)
  blendMethod registry, 'difference', BlendModes.DIFFERENCE

  # exclusion(#f00, #00F)
  blendMethod registry, 'exclusion', BlendModes.EXCLUSION

  # average(#f00, #00F)
  blendMethod registry, 'average', BlendModes.AVERAGE

  # negation(#f00, #00F)
  blendMethod registry, 'negation', BlendModes.NEGATION

  if context?.hasColorVariables()
    paletteRegexpString = createVariableRegExpString(context.getColorVariables())

    registry.createExpression 'variables', paletteRegexpString, 1, (match, expression, context) ->
      [_,_,name] = match
      baseColor = context.readColor(name)
      @colorExpression = name
      @variables = baseColor?.variables

      return @invalid = true if isInvalid(baseColor)

      @rgba = baseColor.rgba

  registry
