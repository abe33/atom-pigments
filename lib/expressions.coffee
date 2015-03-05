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
  clamp
  clampInt
} = require './utils'

ExpressionsRegistry = require './expressions-registry'
ColorExpression = require './color-expression'
SVGColors = require './svg-colors'

module.exports = registry = new ExpressionsRegistry(ColorExpression)

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

  @name = name
  @hex = SVGColors.allCases[name].replace('#','')

##    ######## ##     ## ##    ##  ######
##    ##       ##     ## ###   ## ##    ##
##    ##       ##     ## ####  ## ##
##    ######   ##     ## ## ## ## ##
##    ##       ##     ## ##  #### ##
##    ##       ##     ## ##   ### ##    ##
##    ##        #######  ##    ##  ######
