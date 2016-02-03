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
} = require './regexes'

{strip} = require './utils'

ExpressionsRegistry = require './expressions-registry'
ColorExpression = require './color-expression'
SVGColors = require './svg-colors'

module.exports =
registry = new ExpressionsRegistry(ColorExpression)

##    ##       #### ######## ######## ########     ###    ##
##    ##        ##     ##    ##       ##     ##   ## ##   ##
##    ##        ##     ##    ##       ##     ##  ##   ##  ##
##    ##        ##     ##    ######   ########  ##     ## ##
##    ##        ##     ##    ##       ##   ##   ######### ##
##    ##        ##     ##    ##       ##    ##  ##     ## ##
##    ######## ####    ##    ######## ##     ## ##     ## ########

# #6f3489ef
registry.createExpression 'pigments:css_hexa_8', "#(#{hexadecimal}{8})(?![\\d\\w])", ['css', 'less', 'styl', 'stylus', 'sass', 'scss'], (match, expression, context) ->
  [_, hexa] = match

  @hexRGBA = hexa

# #6f3489ef
registry.createExpression 'pigments:argb_hexa_8', "#(#{hexadecimal}{8})(?![\\d\\w])", ['*'], (match, expression, context) ->
  [_, hexa] = match

  @hexARGB = hexa

# #3489ef
registry.createExpression 'pigments:css_hexa_6', "#(#{hexadecimal}{6})(?![\\d\\w])", ['*'], (match, expression, context) ->
  [_, hexa] = match

  @hex = hexa

# #6f34
registry.createExpression 'pigments:css_hexa_4', "(?:#{namePrefixes})#(#{hexadecimal}{4})(?![\\d\\w])", ['*'], (match, expression, context) ->
  [_, hexa] = match
  colorAsInt = context.readInt(hexa, 16)

  @colorExpression = "##{hexa}"
  @red = (colorAsInt >> 12 & 0xf) * 17
  @green = (colorAsInt >> 8 & 0xf) * 17
  @blue = (colorAsInt >> 4 & 0xf) * 17
  @alpha = ((colorAsInt & 0xf) * 17) / 255

# #38e
registry.createExpression 'pigments:css_hexa_3', "(?:#{namePrefixes})#(#{hexadecimal}{3})(?![\\d\\w])", ['*'], (match, expression, context) ->
  [_, hexa] = match
  colorAsInt = context.readInt(hexa, 16)

  @colorExpression = "##{hexa}"
  @red = (colorAsInt >> 8 & 0xf) * 17
  @green = (colorAsInt >> 4 & 0xf) * 17
  @blue = (colorAsInt & 0xf) * 17

# 0xab3489ef
registry.createExpression 'pigments:int_hexa_8', "0x(#{hexadecimal}{8})(?!#{hexadecimal})", ['*'], (match, expression, context) ->
  [_, hexa] = match

  @hexARGB = hexa

# 0x3489ef
registry.createExpression 'pigments:int_hexa_6', "0x(#{hexadecimal}{6})(?!#{hexadecimal})", ['*'], (match, expression, context) ->
  [_, hexa] = match

  @hex = hexa

# rgb(50,120,200)
registry.createExpression 'pigments:css_rgb', strip("
  rgb#{ps}\\s*
    (#{intOrPercent}|#{variables})
    #{comma}
    (#{intOrPercent}|#{variables})
    #{comma}
    (#{intOrPercent}|#{variables})
  #{pe}
"), ['*'], (match, expression, context) ->
  [_,r,g,b] = match

  @red = context.readIntOrPercent(r)
  @green = context.readIntOrPercent(g)
  @blue = context.readIntOrPercent(b)
  @alpha = 1

# rgba(50,120,200,0.7)
registry.createExpression 'pigments:css_rgba', strip("
  rgba#{ps}\\s*
    (#{intOrPercent}|#{variables})
    #{comma}
    (#{intOrPercent}|#{variables})
    #{comma}
    (#{intOrPercent}|#{variables})
    #{comma}
    (#{float}|#{variables})
  #{pe}
"), ['*'], (match, expression, context) ->
  [_,r,g,b,a] = match

  @red = context.readIntOrPercent(r)
  @green = context.readIntOrPercent(g)
  @blue = context.readIntOrPercent(b)
  @alpha = context.readFloat(a)

# rgba(green,0.7)
registry.createExpression 'pigments:stylus_rgba', strip("
  rgba#{ps}\\s*
    (#{notQuote})
    #{comma}
    (#{float}|#{variables})
  #{pe}
"), ['*'], (match, expression, context) ->
  [_,subexpr,a] = match

  baseColor = context.readColor(subexpr)

  return @invalid = true if context.isInvalid(baseColor)

  @rgb = baseColor.rgb
  @alpha = context.readFloat(a)

# hsl(210,50%,50%)
registry.createExpression 'pigments:css_hsl', strip("
  hsl#{ps}\\s*
    (#{float}|#{variables})
    #{comma}
    (#{optionalPercent}|#{variables})
    #{comma}
    (#{optionalPercent}|#{variables})
  #{pe}
"), ['*'], (match, expression, context) ->
  [_,h,s,l] = match

  hsl = [
    context.readInt(h)
    context.readFloat(s)
    context.readFloat(l)
  ]

  return @invalid = true if hsl.some (v) -> not v? or isNaN(v)

  @hsl = hsl
  @alpha = 1

# hsla(210,50%,50%,0.7)
registry.createExpression 'pigments:css_hsla', strip("
  hsla#{ps}\\s*
    (#{float}|#{variables})
    #{comma}
    (#{optionalPercent}|#{variables})
    #{comma}
    (#{optionalPercent}|#{variables})
    #{comma}
    (#{float}|#{variables})
  #{pe}
"), ['*'], (match, expression, context) ->
  [_,h,s,l,a] = match

  hsl = [
    context.readInt(h)
    context.readFloat(s)
    context.readFloat(l)
  ]

  return @invalid = true if hsl.some (v) -> not v? or isNaN(v)

  @hsl = hsl
  @alpha = context.readFloat(a)

# hsv(210,70%,90%)
registry.createExpression 'pigments:hsv', strip("
  (?:hsv|hsb)#{ps}\\s*
    (#{float}|#{variables})
    #{comma}
    (#{optionalPercent}|#{variables})
    #{comma}
    (#{optionalPercent}|#{variables})
  #{pe}
"), ['*'], (match, expression, context) ->
  [_,h,s,v] = match

  hsv = [
    context.readInt(h)
    context.readFloat(s)
    context.readFloat(v)
  ]

  return @invalid = true if hsv.some (v) -> not v? or isNaN(v)

  @hsv = hsv
  @alpha = 1

# hsva(210,70%,90%,0.7)
registry.createExpression 'pigments:hsva', strip("
  (?:hsva|hsba)#{ps}\\s*
    (#{float}|#{variables})
    #{comma}
    (#{optionalPercent}|#{variables})
    #{comma}
    (#{optionalPercent}|#{variables})
    #{comma}
    (#{float}|#{variables})
  #{pe}
"), ['*'], (match, expression, context) ->
  [_,h,s,v,a] = match

  hsv = [
    context.readInt(h)
    context.readFloat(s)
    context.readFloat(v)
  ]

  return @invalid = true if hsv.some (v) -> not v? or isNaN(v)

  @hsv = hsv
  @alpha = context.readFloat(a)

# vec4(0.2, 0.5, 0.9, 0.7)
registry.createExpression 'pigments:vec4', strip("
  vec4#{ps}\\s*
    (#{float})
    #{comma}
    (#{float})
    #{comma}
    (#{float})
    #{comma}
    (#{float})
  #{pe}
"), ['*'], (match, expression, context) ->
  [_,h,s,l,a] = match

  @rgba = [
    context.readFloat(h) * 255
    context.readFloat(s) * 255
    context.readFloat(l) * 255
    context.readFloat(a)
  ]

# hwb(210,40%,40%)
registry.createExpression 'pigments:hwb', strip("
  hwb#{ps}\\s*
    (#{float}|#{variables})
    #{comma}
    (#{optionalPercent}|#{variables})
    #{comma}
    (#{optionalPercent}|#{variables})
    (?:#{comma}(#{float}|#{variables}))?
  #{pe}
"), ['*'], (match, expression, context) ->
  [_,h,w,b,a] = match

  @hwb = [
    context.readInt(h)
    context.readFloat(w)
    context.readFloat(b)
  ]
  @alpha = if a? then context.readFloat(a) else 1

# gray(50%)
# The priority is set to 1 to make sure that it appears before named colors
registry.createExpression 'pigments:gray', strip("
  gray#{ps}\\s*
    (#{optionalPercent}|#{variables})
    (?:#{comma}(#{float}|#{variables}))?
  #{pe}"), 1, ['*'], (match, expression, context) ->

  [_,p,a] = match

  p = context.readFloat(p) / 100 * 255
  @rgb = [p, p, p]
  @alpha = if a? then context.readFloat(a) else 1

# dodgerblue
colors = Object.keys(SVGColors.allCases)
colorRegexp = "(?:#{namePrefixes})(#{colors.join('|')})\\b(?![ \\t]*[-\\.:=\\(])"

registry.createExpression 'pigments:named_colors', colorRegexp, ['*'], (match, expression, context) ->
  [_,name] = match

  @colorExpression = @name = name
  @hex = context.SVGColors.allCases[name].replace('#','')

##    ######## ##     ## ##    ##  ######
##    ##       ##     ## ###   ## ##    ##
##    ##       ##     ## ####  ## ##
##    ######   ##     ## ## ## ## ##
##    ##       ##     ## ##  #### ##
##    ##       ##     ## ##   ### ##    ##
##    ##        #######  ##    ##  ######

# darken(#666666, 20%)
registry.createExpression 'pigments:darken', strip("
  darken#{ps}
    (#{notQuote})
    #{comma}
    (#{optionalPercent}|#{variables})
  #{pe}
"), ['*'], (match, expression, context) ->
  [_, subexpr, amount] = match

  amount = context.readFloat(amount)
  baseColor = context.readColor(subexpr)

  return @invalid = true if context.isInvalid(baseColor)

  [h,s,l] = baseColor.hsl

  @hsl = [h, s, context.clampInt(l - amount)]
  @alpha = baseColor.alpha

# lighten(#666666, 20%)
registry.createExpression 'pigments:lighten', strip("
  lighten#{ps}
    (#{notQuote})
    #{comma}
    (#{optionalPercent}|#{variables})
  #{pe}
"), ['*'], (match, expression, context) ->
  [_, subexpr, amount] = match

  amount = context.readFloat(amount)
  baseColor = context.readColor(subexpr)

  return @invalid = true if context.isInvalid(baseColor)

  [h,s,l] = baseColor.hsl

  @hsl = [h, s, context.clampInt(l + amount)]
  @alpha = baseColor.alpha

# fade(#ffffff, 0.5)
# alpha(#ffffff, 0.5)
registry.createExpression 'pigments:fade', strip("
  (?:fade|alpha)#{ps}
    (#{notQuote})
    #{comma}
    (#{floatOrPercent}|#{variables})
  #{pe}
"), ['*'], (match, expression, context) ->
  [_, subexpr, amount] = match

  amount = context.readFloatOrPercent(amount)
  baseColor = context.readColor(subexpr)

  return @invalid = true if context.isInvalid(baseColor)

  @rgb = baseColor.rgb
  @alpha = amount

# transparentize(#ffffff, 0.5)
# transparentize(#ffffff, 50%)
# fadeout(#ffffff, 0.5)
registry.createExpression 'pigments:transparentize', strip("
  (?:transparentize|fadeout|fade-out|fade_out)#{ps}
    (#{notQuote})
    #{comma}
    (#{floatOrPercent}|#{variables})
  #{pe}
"), ['*'], (match, expression, context) ->
  [_, subexpr, amount] = match

  amount = context.readFloatOrPercent(amount)
  baseColor = context.readColor(subexpr)

  return @invalid = true if context.isInvalid(baseColor)

  @rgb = baseColor.rgb
  @alpha = context.clamp(baseColor.alpha - amount)

# opacify(0x78ffffff, 0.5)
# opacify(0x78ffffff, 50%)
# fadein(0x78ffffff, 0.5)
# alpha(0x78ffffff, 0.5)
registry.createExpression 'pigments:opacify', strip("
  (?:opacify|fadein|fade-in|fade_in)#{ps}
    (#{notQuote})
    #{comma}
    (#{floatOrPercent}|#{variables})
  #{pe}
"), ['*'], (match, expression, context) ->
  [_, subexpr, amount] = match

  amount = context.readFloatOrPercent(amount)
  baseColor = context.readColor(subexpr)

  return @invalid = true if context.isInvalid(baseColor)

  @rgb = baseColor.rgb
  @alpha = context.clamp(baseColor.alpha + amount)

# red(#000,255)
# green(#000,255)
# blue(#000,255)
registry.createExpression 'pigments:stylus_component_functions', strip("
  (red|green|blue)#{ps}
    (#{notQuote})
    #{comma}
    (#{int}|#{variables})
  #{pe}
"), ['*'], (match, expression, context) ->
  [_, channel, subexpr, amount] = match

  amount = context.readInt(amount)
  baseColor = context.readColor(subexpr)

  return @invalid = true if context.isInvalid(baseColor)
  return @invalid = true if isNaN(amount)

  @[channel] = amount

# transparentify(#808080)
registry.createExpression 'pigments:transparentify', strip("
  transparentify#{ps}
  (#{notQuote})
  #{pe}
"), ['*'], (match, expression, context) ->
  [_, expr] = match

  [top, bottom, alpha] = context.split(expr)

  top = context.readColor(top)
  bottom = context.readColor(bottom)
  alpha = context.readFloatOrPercent(alpha)

  return @invalid = true if context.isInvalid(top)
  return @invalid = true if bottom? and context.isInvalid(bottom)

  bottom ?= new context.Color(255,255,255,1)
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
registry.createExpression 'pigments:hue', strip("
  hue#{ps}
    (#{notQuote})
    #{comma}
    (#{int}deg|#{variables})
  #{pe}
"), ['*'], (match, expression, context) ->
  [_, subexpr, amount] = match

  amount = context.readFloat(amount)
  baseColor = context.readColor(subexpr)

  return @invalid = true if context.isInvalid(baseColor)
  return @invalid = true if isNaN(amount)

  [h,s,l] = baseColor.hsl

  @hsl = [amount % 360, s, l]
  @alpha = baseColor.alpha

# saturation(#855, 60deg)
# lightness(#855, 60deg)
registry.createExpression 'pigments:stylus_sl_component_functions', strip("
  (saturation|lightness)#{ps}
    (#{notQuote})
    #{comma}
    (#{intOrPercent}|#{variables})
  #{pe}
"), ['*'], (match, expression, context) ->
  [_, channel, subexpr, amount] = match

  amount = context.readInt(amount)
  baseColor = context.readColor(subexpr)

  return @invalid = true if context.isInvalid(baseColor)
  return @invalid = true if isNaN(amount)

  baseColor[channel] = amount
  @rgba = baseColor.rgba

# adjust-hue(#855, 60deg)
registry.createExpression 'pigments:adjust-hue', strip("
  adjust-hue#{ps}
    (#{notQuote})
    #{comma}
    (-?#{int}deg|#{variables}|-?#{optionalPercent})
  #{pe}
"), ['*'], (match, expression, context) ->
  [_, subexpr, amount] = match

  amount = context.readFloat(amount)
  baseColor = context.readColor(subexpr)

  return @invalid = true if context.isInvalid(baseColor)

  [h,s,l] = baseColor.hsl

  @hsl = [(h + amount) % 360, s, l]
  @alpha = baseColor.alpha

# mix(#f00, #00F, 25%)
# mix(#f00, #00F)
registry.createExpression 'pigments:mix', "mix#{ps}(#{notQuote})#{pe}", ['*'], (match, expression, context) ->
  [_, expr] = match

  [color1, color2, amount] = context.split(expr)

  if amount?
    amount = context.readFloatOrPercent(amount)
  else
    amount = 0.5

  baseColor1 = context.readColor(color1)
  baseColor2 = context.readColor(color2)

  return @invalid = true if context.isInvalid(baseColor1) or context.isInvalid(baseColor2)

  {@rgba} = context.mixColors(baseColor1, baseColor2, amount)

# tint(red, 50%)
registry.createExpression 'pigments:stylus_tint', strip("
  tint#{ps}
    (#{notQuote})
    #{comma}
    (#{floatOrPercent}|#{variables})
  #{pe}
"), ['styl', 'stylus', 'less'], (match, expression, context) ->
  [_, subexpr, amount] = match

  amount = context.readFloatOrPercent(amount)
  baseColor = context.readColor(subexpr)

  return @invalid = true if context.isInvalid(baseColor)

  white = new context.Color(255, 255, 255)

  @rgba = context.mixColors(white, baseColor, amount).rgba

# shade(red, 50%)
registry.createExpression 'pigments:stylus_shade', strip("
  shade#{ps}
    (#{notQuote})
    #{comma}
    (#{floatOrPercent}|#{variables})
  #{pe}
"), ['styl', 'stylus', 'less'], (match, expression, context) ->
  [_, subexpr, amount] = match

  amount = context.readFloatOrPercent(amount)
  baseColor = context.readColor(subexpr)

  return @invalid = true if context.isInvalid(baseColor)

  black = new context.Color(0,0,0)

  @rgba = context.mixColors(black, baseColor, amount).rgba

# tint(red, 50%)
registry.createExpression 'pigments:sass_tint', strip("
  tint#{ps}
    (#{notQuote})
    #{comma}
    (#{floatOrPercent}|#{variables})
  #{pe}
"), ['sass', 'scss'], (match, expression, context) ->
  [_, subexpr, amount] = match

  amount = context.readFloatOrPercent(amount)
  baseColor = context.readColor(subexpr)

  return @invalid = true if context.isInvalid(baseColor)

  white = new context.Color(255, 255, 255)

  @rgba = context.mixColors(baseColor, white, amount).rgba

# shade(red, 50%)
registry.createExpression 'pigments:sass_shade', strip("
  shade#{ps}
    (#{notQuote})
    #{comma}
    (#{floatOrPercent}|#{variables})
  #{pe}
"), ['sass', 'scss'], (match, expression, context) ->
  [_, subexpr, amount] = match

  amount = context.readFloatOrPercent(amount)
  baseColor = context.readColor(subexpr)

  return @invalid = true if context.isInvalid(baseColor)

  black = new context.Color(0,0,0)

  @rgba = context.mixColors(baseColor, black, amount).rgba

# desaturate(#855, 20%)
# desaturate(#855, 0.2)
registry.createExpression 'pigments:desaturate', "desaturate#{ps}(#{notQuote})#{comma}(#{floatOrPercent}|#{variables})#{pe}", ['*'], (match, expression, context) ->
  [_, subexpr, amount] = match

  amount = context.readFloatOrPercent(amount)
  baseColor = context.readColor(subexpr)

  return @invalid = true if context.isInvalid(baseColor)

  [h,s,l] = baseColor.hsl

  @hsl = [h, context.clampInt(s - amount * 100), l]
  @alpha = baseColor.alpha

# saturate(#855, 20%)
# saturate(#855, 0.2)
registry.createExpression 'pigments:saturate', strip("
  saturate#{ps}
    (#{notQuote})
    #{comma}
    (#{floatOrPercent}|#{variables})
  #{pe}
"), ['*'], (match, expression, context) ->
  [_, subexpr, amount] = match

  amount = context.readFloatOrPercent(amount)
  baseColor = context.readColor(subexpr)

  return @invalid = true if context.isInvalid(baseColor)

  [h,s,l] = baseColor.hsl

  @hsl = [h, context.clampInt(s + amount * 100), l]
  @alpha = baseColor.alpha

# grayscale(red)
# greyscale(red)
registry.createExpression 'pigments:grayscale', "gr(?:a|e)yscale#{ps}(#{notQuote})#{pe}", ['*'], (match, expression, context) ->
  [_, subexpr] = match

  baseColor = context.readColor(subexpr)

  return @invalid = true if context.isInvalid(baseColor)

  [h,s,l] = baseColor.hsl

  @hsl = [h, 0, l]
  @alpha = baseColor.alpha

# invert(green)
registry.createExpression 'pigments:invert', "invert#{ps}(#{notQuote})#{pe}", ['*'], (match, expression, context) ->
  [_, subexpr] = match

  baseColor = context.readColor(subexpr)

  return @invalid = true if context.isInvalid(baseColor)

  [r,g,b] = baseColor.rgb

  @rgb = [255 - r, 255 - g, 255 - b]
  @alpha = baseColor.alpha

# complement(green)
registry.createExpression 'pigments:complement', "complement#{ps}(#{notQuote})#{pe}", ['*'], (match, expression, context) ->
  [_, subexpr] = match

  baseColor = context.readColor(subexpr)

  return @invalid = true if context.isInvalid(baseColor)

  [h,s,l] = baseColor.hsl

  @hsl = [(h + 180) % 360, s, l]
  @alpha = baseColor.alpha

# spin(green, 20)
# spin(green, 20deg)
registry.createExpression 'pigments:spin', strip("
  spin#{ps}
    (#{notQuote})
    #{comma}
    (-?(#{int})(deg)?|#{variables})
  #{pe}
"), ['*'], (match, expression, context) ->
  [_, subexpr, angle] = match

  baseColor = context.readColor(subexpr)
  angle = context.readInt(angle)

  return @invalid = true if context.isInvalid(baseColor)

  [h,s,l] = baseColor.hsl

  @hsl = [(360 + h + angle) % 360, s, l]
  @alpha = baseColor.alpha

# contrast(#666666, #111111, #999999, threshold)
registry.createExpression 'pigments:contrast_n_arguments', strip("
  contrast#{ps}
    (
      #{notQuote}
      #{comma}
      #{notQuote}
    )
  #{pe}
"), ['*'], (match, expression, context) ->
  [_, expr] = match

  [base, dark, light, threshold] = context.split(expr)

  baseColor = context.readColor(base)
  dark = context.readColor(dark)
  light = context.readColor(light)
  threshold = context.readPercent(threshold) if threshold?

  return @invalid = true if context.isInvalid(baseColor)
  return @invalid = true if dark?.invalid
  return @invalid = true if light?.invalid

  res = context.contrast(baseColor, dark, light)

  return @invalid = true if context.isInvalid(res)

  {@rgb} = context.contrast(baseColor, dark, light, threshold)

# contrast(#666666)
registry.createExpression 'pigments:contrast_1_argument', strip("
  contrast#{ps}
    (#{notQuote})
  #{pe}
"), ['*'], (match, expression, context) ->
  [_, subexpr] = match

  baseColor = context.readColor(subexpr)

  return @invalid = true if context.isInvalid(baseColor)

  {@rgb} = context.contrast(baseColor)

# color(green tint(50%))
registry.createExpression 'pigments:css_color_function', "(?:#{namePrefixes})(color#{ps}(#{notQuote})#{pe})", ['*'], (match, expression, context) ->
  try
    [_,expr] = match
    for k,v of context.vars
      expr = expr.replace(///
        #{k.replace(/\(/g, '\\(').replace(/\)/g, '\\)')}
      ///g, v.value)

    cssColor = require 'css-color-function'
    rgba = cssColor.convert(expr)
    @rgba = context.readColor(rgba).rgba
    @colorExpression = expr
  catch e
    @invalid = true

# adjust-color(red, $lightness: 30%)
registry.createExpression 'pigments:sass_adjust_color', "adjust-color#{ps}(#{notQuote})#{pe}", 1, ['*'], (match, expression, context) ->
  [_, subexpr] = match
  res = context.split(subexpr)
  subject = res[0]
  params = res.slice(1)

  baseColor = context.readColor(subject)

  return @invalid = true if context.isInvalid(baseColor)

  for param in params
    context.readParam param, (name, value) ->
      baseColor[name] += context.readFloat(value)

  @rgba = baseColor.rgba

# scale-color(red, $lightness: 30%)
registry.createExpression 'pigments:sass_scale_color', "scale-color#{ps}(#{notQuote})#{pe}", 1, ['*'], (match, expression, context) ->
  MAX_PER_COMPONENT =
    red: 255
    green: 255
    blue: 255
    alpha: 1
    hue: 360
    saturation: 100
    lightness: 100

  [_, subexpr] = match
  res = context.split(subexpr)
  subject = res[0]
  params = res.slice(1)

  baseColor = context.readColor(subject)

  return @invalid = true if context.isInvalid(baseColor)

  for param in params
    context.readParam param, (name, value) ->
      value = context.readFloat(value) / 100

      result = if value > 0
        dif = MAX_PER_COMPONENT[name] - baseColor[name]
        result = baseColor[name] + dif * value
      else
        result = baseColor[name] * (1 + value)

      baseColor[name] = result

  @rgba = baseColor.rgba

# change-color(red, $lightness: 30%)
registry.createExpression 'pigments:sass_change_color', "change-color#{ps}(#{notQuote})#{pe}", 1, ['*'], (match, expression, context) ->
  [_, subexpr] = match
  res = context.split(subexpr)
  subject = res[0]
  params = res.slice(1)

  baseColor = context.readColor(subject)

  return @invalid = true if context.isInvalid(baseColor)

  for param in params
    context.readParam param, (name, value) ->
      baseColor[name] = context.readFloat(value)

  @rgba = baseColor.rgba

# blend(rgba(#FFDE00,.42), 0x19C261)
registry.createExpression 'pigments:stylus_blend', strip("
  blend#{ps}
    (
      #{notQuote}
      #{comma}
      #{notQuote}
    )
  #{pe}
"), ['*'], (match, expression, context) ->
  [_, expr] = match

  [color1, color2] = context.split(expr)

  baseColor1 = context.readColor(color1)
  baseColor2 = context.readColor(color2)

  return @invalid = true if context.isInvalid(baseColor1) or context.isInvalid(baseColor2)

  @rgba = [
    baseColor1.red * baseColor1.alpha + baseColor2.red * (1 - baseColor1.alpha)
    baseColor1.green * baseColor1.alpha + baseColor2.green * (1 - baseColor1.alpha)
    baseColor1.blue * baseColor1.alpha + baseColor2.blue * (1 - baseColor1.alpha)
    baseColor1.alpha + baseColor2.alpha - baseColor1.alpha * baseColor2.alpha
  ]

# Color(50,120,200,255)
registry.createExpression 'pigments:lua_rgba', strip("
  (?:#{namePrefixes})Color#{ps}\\s*
    (#{int}|#{variables})
    #{comma}
    (#{int}|#{variables})
    #{comma}
    (#{int}|#{variables})
    #{comma}
    (#{int}|#{variables})
  #{pe}
"), ['lua'], (match, expression, context) ->
  [_,r,g,b,a] = match

  @red = context.readInt(r)
  @green = context.readInt(g)
  @blue = context.readInt(b)
  @alpha = context.readInt(a) / 255

##    ########  ##       ######## ##    ## ########
##    ##     ## ##       ##       ###   ## ##     ##
##    ##     ## ##       ##       ####  ## ##     ##
##    ########  ##       ######   ## ## ## ##     ##
##    ##     ## ##       ##       ##  #### ##     ##
##    ##     ## ##       ##       ##   ### ##     ##
##    ########  ######## ######## ##    ## ########

# multiply(#f00, #00F)
registry.createExpression 'pigments:multiply', strip("
  multiply#{ps}
    (
      #{notQuote}
      #{comma}
      #{notQuote}
    )
  #{pe}
"), ['*'], (match, expression, context) ->
  [_, expr] = match

  [color1, color2] = context.split(expr)

  baseColor1 = context.readColor(color1)
  baseColor2 = context.readColor(color2)

  return @invalid = true if context.isInvalid(baseColor1) or context.isInvalid(baseColor2)

  {@rgba} = baseColor1.blend(baseColor2, context.BlendModes.MULTIPLY)

# screen(#f00, #00F)
registry.createExpression 'pigments:screen', strip("
  screen#{ps}
    (
      #{notQuote}
      #{comma}
      #{notQuote}
    )
  #{pe}
"), ['*'], (match, expression, context) ->
  [_, expr] = match

  [color1, color2] = context.split(expr)

  baseColor1 = context.readColor(color1)
  baseColor2 = context.readColor(color2)

  return @invalid = true if context.isInvalid(baseColor1) or context.isInvalid(baseColor2)

  {@rgba} = baseColor1.blend(baseColor2, context.BlendModes.SCREEN)


# overlay(#f00, #00F)
registry.createExpression 'pigments:overlay', strip("
  overlay#{ps}
    (
      #{notQuote}
      #{comma}
      #{notQuote}
    )
  #{pe}
"), ['*'], (match, expression, context) ->
  [_, expr] = match

  [color1, color2] = context.split(expr)

  baseColor1 = context.readColor(color1)
  baseColor2 = context.readColor(color2)

  return @invalid = true if context.isInvalid(baseColor1) or context.isInvalid(baseColor2)

  {@rgba} = baseColor1.blend(baseColor2, context.BlendModes.OVERLAY)


# softlight(#f00, #00F)
registry.createExpression 'pigments:softlight', strip("
  softlight#{ps}
    (
      #{notQuote}
      #{comma}
      #{notQuote}
    )
  #{pe}
"), ['*'], (match, expression, context) ->
  [_, expr] = match

  [color1, color2] = context.split(expr)

  baseColor1 = context.readColor(color1)
  baseColor2 = context.readColor(color2)

  return @invalid = true if context.isInvalid(baseColor1) or context.isInvalid(baseColor2)

  {@rgba} = baseColor1.blend(baseColor2, context.BlendModes.SOFT_LIGHT)


# hardlight(#f00, #00F)
registry.createExpression 'pigments:hardlight', strip("
  hardlight#{ps}
    (
      #{notQuote}
      #{comma}
      #{notQuote}
    )
  #{pe}
"), ['*'], (match, expression, context) ->
  [_, expr] = match

  [color1, color2] = context.split(expr)

  baseColor1 = context.readColor(color1)
  baseColor2 = context.readColor(color2)

  return @invalid = true if context.isInvalid(baseColor1) or context.isInvalid(baseColor2)

  {@rgba} = baseColor1.blend(baseColor2, context.BlendModes.HARD_LIGHT)


# difference(#f00, #00F)
registry.createExpression 'pigments:difference', strip("
  difference#{ps}
    (
      #{notQuote}
      #{comma}
      #{notQuote}
    )
  #{pe}
"), ['*'], (match, expression, context) ->
  [_, expr] = match

  [color1, color2] = context.split(expr)

  baseColor1 = context.readColor(color1)
  baseColor2 = context.readColor(color2)

  return @invalid = true if context.isInvalid(baseColor1) or context.isInvalid(baseColor2)

  {@rgba} = baseColor1.blend(baseColor2, context.BlendModes.DIFFERENCE)

# exclusion(#f00, #00F)
registry.createExpression 'pigments:exclusion', strip("
  exclusion#{ps}
    (
      #{notQuote}
      #{comma}
      #{notQuote}
    )
  #{pe}
"), ['*'], (match, expression, context) ->
  [_, expr] = match

  [color1, color2] = context.split(expr)

  baseColor1 = context.readColor(color1)
  baseColor2 = context.readColor(color2)

  return @invalid = true if context.isInvalid(baseColor1) or context.isInvalid(baseColor2)

  {@rgba} = baseColor1.blend(baseColor2, context.BlendModes.EXCLUSION)

# average(#f00, #00F)
registry.createExpression 'pigments:average', strip("
  average#{ps}
    (
      #{notQuote}
      #{comma}
      #{notQuote}
    )
  #{pe}
"), ['*'], (match, expression, context) ->
  [_, expr] = match

  [color1, color2] = context.split(expr)

  baseColor1 = context.readColor(color1)
  baseColor2 = context.readColor(color2)

  return @invalid = true if context.isInvalid(baseColor1) or context.isInvalid(baseColor2)

  {@rgba} = baseColor1.blend(baseColor2, context.BlendModes.AVERAGE)

# negation(#f00, #00F)
registry.createExpression 'pigments:negation', strip("
  negation#{ps}
    (
      #{notQuote}
      #{comma}
      #{notQuote}
    )
  #{pe}
"), ['*'], (match, expression, context) ->
  [_, expr] = match

  [color1, color2] = context.split(expr)

  baseColor1 = context.readColor(color1)
  baseColor2 = context.readColor(color2)

  return @invalid = true if context.isInvalid(baseColor1) or context.isInvalid(baseColor2)

  {@rgba} = baseColor1.blend(baseColor2, context.BlendModes.NEGATION)

##    ######## ##       ##     ##
##    ##       ##       ###   ###
##    ##       ##       #### ####
##    ######   ##       ## ### ##
##    ##       ##       ##     ##
##    ##       ##       ##     ##
##    ######## ######## ##     ##

# rgba 50 120 200 1
registry.createExpression 'pigments:elm_rgba', strip("
  rgba\\s+
    (#{int}|#{variables})
    \\s+
    (#{int}|#{variables})
    \\s+
    (#{int}|#{variables})
    \\s+
    (#{float}|#{variables})
"), ['elm'], (match, expression, context) ->
  [_,r,g,b,a] = match

  @red = context.readInt(r)
  @green = context.readInt(g)
  @blue = context.readInt(b)
  @alpha = context.readFloat(a)

# rgb 50 120 200
registry.createExpression 'pigments:elm_rgb', strip("
  rgb\\s+
    (#{int}|#{variables})
    \\s+
    (#{int}|#{variables})
    \\s+
    (#{int}|#{variables})
"), ['elm'], (match, expression, context) ->
  [_,r,g,b] = match

  @red = context.readInt(r)
  @green = context.readInt(g)
  @blue = context.readInt(b)

elmAngle = "(?:#{float}|\\(degrees\\s+(?:#{int}|#{variables})\\))"

# hsl 210 50 50
registry.createExpression 'pigments:elm_hsl', strip("
  hsl\\s+
    (#{elmAngle}|#{variables})
    \\s+
    (#{float}|#{variables})
    \\s+
    (#{float}|#{variables})
"), ['elm'], (match, expression, context) ->
  elmDegreesRegexp = new RegExp("\\(degrees\\s+(#{context.int}|#{context.variablesRE})\\)")

  [_,h,s,l] = match

  if m = elmDegreesRegexp.exec(h)
    h = context.readInt(m[1])
  else
    h = context.readFloat(h) * 180 / Math.PI

  hsl = [
    h
    context.readFloat(s)
    context.readFloat(l)
  ]

  return @invalid = true if hsl.some (v) -> not v? or isNaN(v)

  @hsl = hsl
  @alpha = 1

# hsla 210 50 50 0.7
registry.createExpression 'pigments:elm_hsla', strip("
  hsla\\s+
    (#{elmAngle}|#{variables})
    \\s+
    (#{float}|#{variables})
    \\s+
    (#{float}|#{variables})
    \\s+
    (#{float}|#{variables})
"), ['elm'], (match, expression, context) ->
  elmDegreesRegexp = new RegExp("\\(degrees\\s+(#{context.int}|#{context.variablesRE})\\)")

  [_,h,s,l,a] = match

  if m = elmDegreesRegexp.exec(h)
    h = context.readInt(m[1])
  else
    h = context.readFloat(h) * 180 / Math.PI

  hsl = [
    h
    context.readFloat(s)
    context.readFloat(l)
  ]

  return @invalid = true if hsl.some (v) -> not v? or isNaN(v)

  @hsl = hsl
  @alpha = context.readFloat(a)

# grayscale 1
registry.createExpression 'pigments:elm_grayscale', "gr(?:a|e)yscale\\s+(#{float}|#{variables})", ['elm'], (match, expression, context) ->
  [_,amount] = match
  amount = Math.floor(255 - context.readFloat(amount) * 255)
  @rgb = [amount, amount, amount]

registry.createExpression 'pigments:elm_complement', strip("
  complement\\s+(#{notQuote})
"), ['elm'], (match, expression, context) ->
  [_, subexpr] = match

  baseColor = context.readColor(subexpr)

  return @invalid = true if context.isInvalid(baseColor)

  [h,s,l] = baseColor.hsl

  @hsl = [(h + 180) % 360, s, l]
  @alpha = baseColor.alpha
