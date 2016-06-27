{
  cmykToRGB
  hexARGBToRGB
  hexRGBAToRGB
  hexToRGB
  hslToRGB
  hsvToHWB
  hsvToRGB
  hwbToHSV
  hwbToRGB
  rgbToCMYK
  rgbToHex
  rgbToHexARGB
  rgbToHexRGBA
  rgbToHSL
  rgbToHSV
  rgbToHWB
} = require './color-conversions'
SVGColors = require './svg-colors'

module.exports =
class Color

  @colorComponents: [
    ['red',   0]
    ['green', 1]
    ['blue',  2]
    ['alpha', 3]
  ]

  @isValid: (color) ->
    color? and not color.invalid and
    color.red? and color.green? and
    color.blue? and color.alpha? and
    not isNaN(color.red) and not isNaN(color.green) and
    not isNaN(color.blue) and not isNaN(color.alpha)

  constructor: (r=0,g=0,b=0,a=1) ->
    if typeof r is 'object'
      if Array.isArray(r)
        @[i] = v for v,i in r
      else
        @[k] = v for k,v of r
    else if typeof r is 'string'
      if r of SVGColors.allCases
        @name = r
        r = SVGColors.allCases[r]

      expr = r.replace(/\#|0x/, '')
      if expr.length is 6
        @hex = expr
        @alpha = 1
      else
        @hexARGB = expr
    else
      [@red, @green, @blue, @alpha] = [r,g,b,a]

  @colorComponents.forEach ([component, index]) ->
    Object.defineProperty Color.prototype, component, {
      enumerable: true
      get: -> @[index]
      set: (component) -> @[index] = component
    }

  Object.defineProperty Color.prototype, 'rgb', {
    enumerable: true
    get: -> [@red, @green, @blue]
    set: ([@red, @green, @blue]) ->
  }

  Object.defineProperty Color.prototype, 'rgba', {
    enumerable: true
    get: -> [@red, @green, @blue, @alpha]
    set: ([@red, @green, @blue, @alpha]) ->
  }

  Object.defineProperty Color.prototype, 'argb', {
    enumerable: true
    get: -> [@alpha, @red, @green, @blue]
    set: ([@alpha, @red, @green, @blue]) ->
  }

  Object.defineProperty Color.prototype, 'hsv', {
    enumerable: true
    get: -> rgbToHSV(@red, @green, @blue)
    set: (hsv) ->
      [@red, @green, @blue] = hsvToRGB.apply(@constructor, hsv)
  }

  Object.defineProperty Color.prototype, 'hsva', {
    enumerable: true
    get: -> @hsv.concat(@alpha)
    set: (hsva) ->
      [h,s,v,@alpha] = hsva
      [@red, @green, @blue] = hsvToRGB.apply(@constructor, [h,s,v])
  }

  Object.defineProperty Color.prototype, 'hsl', {
    enumerable: true
    get: -> rgbToHSL(@red, @green, @blue)
    set: (hsl) ->
      [@red, @green, @blue] = hslToRGB.apply(@constructor, hsl)
  }

  Object.defineProperty Color.prototype, 'hsla', {
    enumerable: true
    get: -> @hsl.concat(@alpha)
    set: (hsl) ->
      [h,s,l,@alpha] = hsl
      [@red, @green, @blue] = hslToRGB.apply(@constructor, [h,s,l])
  }

  Object.defineProperty Color.prototype, 'hwb', {
    enumerable: true
    get: -> rgbToHWB(@red, @green, @blue)
    set: (hwb) ->
      [@red, @green, @blue] = hwbToRGB.apply(@constructor, hwb)
  }

  Object.defineProperty Color.prototype, 'hwba', {
    enumerable: true
    get: -> @hwb.concat(@alpha)
    set: (hwb) ->
      [h,w,b,@alpha] = hwb
      [@red, @green, @blue] = hwbToRGB.apply(@constructor, [h,w,b])
  }

  Object.defineProperty Color.prototype, 'hex', {
    enumerable: true
    get: -> rgbToHex(@red, @green, @blue)
    set: (hex) -> [@red, @green, @blue] = hexToRGB(hex)
  }

  Object.defineProperty Color.prototype, 'hexARGB', {
    enumerable: true
    get: -> rgbToHexARGB(@red, @green, @blue, @alpha)
    set: (hex) -> [@red, @green, @blue, @alpha] = hexARGBToRGB(hex)
  }

  Object.defineProperty Color.prototype, 'hexRGBA', {
    enumerable: true
    get: -> rgbToHexRGBA(@red, @green, @blue, @alpha)
    set: (hex) -> [@red, @green, @blue, @alpha] = hexRGBAToRGB(hex)
  }

  Object.defineProperty Color.prototype, 'cmyk', {
    enumerable: true
    get: -> rgbToCMYK(@red, @green, @blue, @alpha)
    set: (cmyk) ->
      [c,m,y,k] = cmyk
      [@red, @green, @blue] = cmykToRGB(c,m,y,k)
  }

  Object.defineProperty Color.prototype, 'length', {
    enumerable: true
    get: -> 4
  }

  Object.defineProperty Color.prototype, 'hue', {
    enumerable: true
    get: -> @hsl[0]
    set: (hue) ->
      hsl = @hsl
      hsl[0] = hue
      @hsl = hsl
  }

  Object.defineProperty Color.prototype, 'saturation', {
    enumerable: true
    get: -> @hsl[1]
    set: (saturation) ->
      hsl = @hsl
      hsl[1] = saturation
      @hsl = hsl
  }

  Object.defineProperty Color.prototype, 'lightness', {
    enumerable: true
    get: -> @hsl[2]
    set: (lightness) ->
      hsl = @hsl
      hsl[2] = lightness
      @hsl = hsl
  }

  Object.defineProperty Color.prototype, 'luma', {
    enumerable: true
    get: ->
      r = @[0] / 255
      g = @[1] / 255
      b = @[2] / 255
      r = if r <= 0.03928
        r / 12.92
      else
        Math.pow(((r + 0.055) / 1.055), 2.4)
      g = if g <= 0.03928
        g / 12.92
      else
        Math.pow(((g + 0.055) / 1.055), 2.4)
      b = if b <= 0.03928
        b / 12.92
      else
        Math.pow(((b + 0.055) / 1.055), 2.4)

      0.2126 * r + 0.7152 * g + 0.0722 * b
  }

  isLiteral: -> not @variables? or @variables.length is 0

  isValid: ->
    @constructor.isValid(this)

  clone: -> new Color(@red, @green, @blue, @alpha)

  isEqual: (color) ->
    color.red is @red and
    color.green is @green and
    color.blue is @blue and
    color.alpha is @alpha

  interpolate: (col, ratio, preserveAlpha=true) ->
    iratio = 1 - ratio

    return clone() unless col?

    new Color(
      Math.floor(@red * iratio + col.red * ratio),
      Math.floor(@green * iratio + col.green * ratio),
      Math.floor(@blue * iratio + col.blue * ratio),
      Math.floor(if preserveAlpha then @alpha else @alpha * iratio + col.alpha * ratio))

  transparentize: (alpha) ->
    new Color(@red, @green, @blue, alpha)

  blend: (color, method, preserveAlpha=true) ->
    r = method(@red, color.red)
    g = method(@green, color.green)
    b = method(@blue, color.blue)
    a = if preserveAlpha then @alpha else method(@alpha, color.alpha)

    new Color(r,g,b,a)

  # Public: Returns a {String} reprensenting the color with the CSS `rgba`
  # notation.
  toCSS: ->
    rnd = Math.round

    if @alpha is 1
      "rgb(#{rnd @red},#{rnd @green},#{rnd @blue})"
    else
      "rgba(#{rnd @red},#{rnd @green},#{rnd @blue},#{@alpha})"

  serialize: ->
    [@red, @green, @blue, @alpha]
