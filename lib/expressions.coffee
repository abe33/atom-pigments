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
  readInt
  readFloat
  readIntOrPercent
  readFloatOrPercent
} = require './utils'

ExpressionsRegistry = require './expressions-registry'

module.exports = registry = new ExpressionsRegistry

##    ##       #### ######## ######## ########     ###    ##
##    ##        ##     ##    ##       ##     ##   ## ##   ##
##    ##        ##     ##    ##       ##     ##  ##   ##  ##
##    ##        ##     ##    ######   ########  ##     ## ##
##    ##        ##     ##    ##       ##   ##   ######### ##
##    ##        ##     ##    ##       ##    ##  ##     ## ##
##    ######## ####    ##    ######## ##     ## ##     ## ########

# #6f3489ef
registry.addExpression 'css_hexa_8', "#(#{hexa}{8})(?![\\d\\w])", (match, expression) ->
  [_, hexa] = match

  @hexARGB = hexa

# #3489ef
registry.addExpression 'css_hexa_6', "#(#{hexa}{6})(?![\\d\\w])", (match, expression) ->
  [_, hexa] = match

  @hex = hexa

# #38e
registry.addExpression 'css_hexa_3', "#(#{hexa}{3})(?![\\d\\w])", (match, expression) ->
  [_, hexa] = match
  colorAsInt = readInt(hexa, {}, this, 16)

  @red = (colorAsInt >> 8 & 0xf) * 17
  @green = (colorAsInt >> 4 & 0xf) * 17
  @blue = (colorAsInt & 0xf) * 17

# 0xab3489ef
registry.addExpression 'int_hexa_8', "0x(#{hexa}{8})(?!#{hexa})", (match, expression) ->
  [_, hexa] = match

  @hexARGB = hexa

# 0x3489ef
registry.addExpression 'int_hexa_6', "0x(#{hexa}{6})(?!#{hexa})", (match, expression) ->
  [_, hexa] = match

  @hex = hexa

# rgb(50,120,200)
registry.addExpression 'css_rgb', strip("
  rgb#{ps}\\s*
    (#{intOrPercent}|#{variables})
    #{comma}
    (#{intOrPercent}|#{variables})
    #{comma}
    (#{intOrPercent}|#{variables})
  #{pe}
"), (match, expression, vars) ->
  [_,r,_,_,g,_,_,b] = match

  @red = readIntOrPercent(r, vars, this)
  @green = readIntOrPercent(g, vars, this)
  @blue = readIntOrPercent(b, vars, this)
  @alpha = 1

# rgba(50,120,200,0.7)
registry.addExpression 'css_rgba', strip("
  rgba#{ps}\\s*
    (#{intOrPercent}|#{variables})
    #{comma}
    (#{intOrPercent}|#{variables})
    #{comma}
    (#{intOrPercent}|#{variables})
    #{comma}
    (#{float}|#{variables})
  #{pe}
"), (match, expression, vars) ->
  [_,r,_,_,g,_,_,b,_,_,a] = match

  @red = readIntOrPercent(r, vars, this)
  @green = readIntOrPercent(g, vars, this)
  @blue = readIntOrPercent(b, vars, this)
  @alpha = readFloat(a, vars, this)

# rgba(green,0.7)
registry.addExpression 'stylus_rgba', strip("
  rgba#{ps}\\s*
    (#{notQuote})
    #{comma}
    (#{float}|#{variables})
  #{pe}
"), (match, expression, vars) ->
  [_,subexpr,a] = match

  if vars[subexpr]?
    @usedVariables.push(subexpr)
    subexpr = vars[subexpr].value

  if Color.canHandle(subexpr)
    baseColor = new Color(subexpr, vars)
    @rgb = baseColor.rgb
    @alpha = readFloat(a, vars, this)
  else
    @isInvalid = true

# hsl(210,50%,50%)
registry.addExpression 'css_hsl', strip("
  hsl#{ps}\\s*
    (#{int}|#{variables})
    #{comma}
    (#{percent}|#{variables})
    #{comma}
    (#{percent}|#{variables})
  #{pe}
"), (match, expression, vars) ->
  [_,h,_,s,_,l] = match

  @hsl = [
    readInt(h, vars, this)
    readFloat(s, vars, this)
    readFloat(l, vars, this)
  ]
  @alpha = 1

# hsla(210,50%,50%,0.7)
registry.addExpression 'css_hsla', strip("
  hsla#{ps}\\s*
    (#{int}|#{variables})
    #{comma}
    (#{percent}|#{variables})
    #{comma}
    (#{percent}|#{variables})
    #{comma}
    (#{float}|#{variables})
  #{pe}
"), (match, expression, vars) ->
  [_,h,_,s,_,l,_,a] = match

  @hsl = [
    readInt(h, vars, this)
    readFloat(s,vars, this)
    readFloat(l,vars, this)
  ]
  @alpha = readFloat(a,vars, this)

# hsv(210,70%,90%)
registry.addExpression 'hsv', strip("
  hsv#{ps}\\s*
    (#{int}|#{variables})
    #{comma}
    (#{percent}|#{variables})
    #{comma}
    (#{percent}|#{variables})
  #{pe}
"), (match, expression, vars) ->
  [_,h,_,s,_,v] = match

  @hsv = [
    readInt(h, vars, this)
    readFloat(s, vars, this)
    readFloat(v, vars, this)
  ]
  @alpha = 1

# hsva(210,70%,90%,0.7)
registry.addExpression 'hsva', strip("
  hsva#{ps}\\s*
    (#{int}|#{variables})
    #{comma}
    (#{percent}|#{variables})
    #{comma}
    (#{percent}|#{variables})
    #{comma}
    (#{float}|#{variables})
  #{pe}
"), (match, expression, vars) ->
  [_,h,_,s,_,v,_,a] = match

  @hsv = [
    readInt(h, vars, this)
    readFloat(s, vars, this)
    readFloat(v, vars, this)
  ]
  @alpha = readFloat(a, vars, this)


# vec4(0.2, 0.5, 0.9, 0.7)
registry.addExpression 'vec4', strip("
  vec4#{ps}\\s*
    (#{float})
    #{comma}
    (#{float})
    #{comma}
    (#{float})
    #{comma}
    (#{float})
  #{pe}
"), (match, expression) ->
  [_,h,s,l,a] = match

  @rgba = [
    readFloat(h, vars, this) * 255
    readFloat(s, vars, this) * 255
    readFloat(l, vars, this) * 255
    readFloat(a, vars, this)
  ]

# hwb(210,40%,40%)
registry.addExpression 'hwb', strip("
  hwb#{ps}\\s*
    (#{int}|#{variables})
    #{comma}
    (#{percent}|#{variables})
    #{comma}
    (#{percent}|#{variables})
    (#{comma}(#{float}|#{variables}))?
  #{pe}
"), (match, expression, vars) ->
  [_,h,_,w,_,b,_,_,a] = match

  @hwb = [
    readInt(h, vars, this)
    readFloat(w, vars, this)
    readFloat(b, vars, this)
  ]
  @alpha = if a? then readFloat(a, vars, this) else 1

# gray(50%)
# The priority is set to 1 to make sure that it appears before named colors
registry.addExpression 'gray', strip("
  gray#{ps}\\s*
    (#{percent}|#{variables})
    (#{comma}(#{float}|#{variables}))?
  #{pe}"), 1, (match, expression, vars) ->

  [_,p,_,_,a] = match

  p = readFloat(p, vars, this) / 100 * 255
  @rgb = [p, p, p]
  @alpha = if a? then readFloat(a, vars, this) else 1

# dodgerblue
# colors = Object.keys(Color.namedColors)
#
# colorRegexp = "(#{namePrefixes})(#{colors.join('|')})(?!\\s*[-\\.:=\\(])\\b"
#
# registry.addExpression 'named_colors', colorRegexp, (match, expression) ->
#   [_,_,name] = match
#
#   @colorExpression = @name = name

##    ######## ##     ## ##    ##  ######
##    ##       ##     ## ###   ## ##    ##
##    ##       ##     ## ####  ## ##
##    ######   ##     ## ## ## ## ##
##    ##       ##     ## ##  #### ##
##    ##       ##     ## ##   ### ##    ##
##    ##        #######  ##    ##  ######
