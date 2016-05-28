# Public: Converts a color defined with its red, green and blue
# components into an hexadecimal {String}.
#
# r - An integer in the range [O-255] for the red component
# g - An integer in the range [O-255] for the green component
# b - An integer in the range [O-255] for the blue component
#
# Returns an hexadecimal {String} as `RRGGBB`
rgbToHex =  (r, g, b) ->
  rnd = Math.round
  value = ((rnd(r) << 16) + (rnd(g) << 8) + rnd(b)).toString 16

  # The value is filled with `0` to match a length of 6.
  value = "0#{value}" while value.length < 6

  value

# Public: Converts an hexadecimal {String} such as `RRGGBB` into an array
# with the red, green and blue components.
#
# hex - A {String} such as `RRGGBB`
#
# Returns an {Array} containing the red, green and blue components
# of the color
hexToRGB = (hex) ->
  color = parseInt hex, 16

  r = (color >> 16) & 0xff
  g = (color >> 8) & 0xff
  b = color & 0xff

  [r, g, b]

# Public: Converts a color defined with its red, green,
# blue and alpha components into an hexadecimal {String}.
#
# r - An integer in the range [O-255] for the red component
# g - An integer in the range [O-255] for the green component
# b - An integer in the range [O-255] for the blue component
# a - A float in the range [O-1] for the alpha component
#
# Returns an hexadecimal {String} as `AARRGGBB`
rgbToHexARGB = (r, g, b, a) ->
  rnd = Math.round
  value = (
    (rnd(a * 255) << 24) +
    (rnd(r) << 16) +
    (rnd(g) << 8) +
    rnd(b)
  ).toString 16

  # The value is filled with `0` to match a length of 8.
  value = "0#{value}" while value.length < 8

  value

# Public: Converts a color defined with its red, green,
# blue and alpha components into an hexadecimal {String}.
#
# r - An integer in the range [O-255] for the red component
# g - An integer in the range [O-255] for the green component
# b - An integer in the range [O-255] for the blue component
# a - A float in the range [O-1] for the alpha component
#
# Returns an hexadecimal {String} as `RRGGBBAA`
rgbToHexRGBA = (r, g, b, a) ->
  rnd = Math.round
  value = (
    (rnd(r) << 24) +
    (rnd(g) << 16) +
    (rnd(b) << 8) +
    rnd(a * 255)
  ).toString 16

  # The value is filled with `0` to match a length of 8.
  value = "0#{value}" while value.length < 8

  value

# Public: Converts an hexadecimal {String} such as `aarrggbb` into an array
# with the red, green, blue and alpha components values.
#
# hex - A {String} such as `AARRGGBB`
#
# Returns an {Array} containing the red, green, blue and alpha components
# of the color
hexARGBToRGB = (hex) ->
  color = parseInt hex, 16

  a = ((color >> 24) & 0xff) / 255
  r = (color >> 16) & 0xff
  g = (color >> 8) & 0xff
  b = color & 0xff

  [r, g, b, a]


# Public: Converts an hexadecimal {String} such as `rrggbbaa` into an array
# with the red, green, blue and alpha components values.
#
# hex - A {String} such as `RRGGBBAA`
#
# Returns an {Array} containing the red, green, blue and alpha components
# of the color
hexRGBAToRGB = (hex) ->
  color = parseInt hex, 16

  r = ((color >> 24) & 0xff)
  g = (color >> 16) & 0xff
  b = (color >> 8) & 0xff
  a = (color & 0xff) / 255

  [r, g, b, a]

# Public: Converts a color in the `rgb` color space in an
# {Array} with the color in the `hsv` color space.
#
# r - An integer in the range [O-255] for the red component
# g - An integer in the range [O-255] for the green component
# b - An integer in the range [O-255] for the blue component
#
# Returns an {Array} containing the hue, saturation and value of the color
rgbToHSV = (r, g, b) ->

  r = r / 255
  g = g / 255
  b = b / 255
  rnd = Math.round

  minVal = Math.min r, g, b
  maxVal = Math.max r, g, b
  delta = maxVal - minVal

  # Value is always the maximal component's value.
  v = maxVal

  # The color is a gray, there's no need to proceed further.
  # Both saturation and hue equals to `0`.
  if delta is 0
    h = 0
    s = 0
  else
    # The lower the delta is in comparison with the value
    # the higher the saturation will be.
    s = delta / v
    deltaR = (((v - r) / 6) + (delta / 2)) / delta
    deltaG = (((v - g) / 6) + (delta / 2)) / delta
    deltaB = (((v - b) / 6) + (delta / 2)) / delta

    # In a range from `0` to `1`, full red is at `0` and `1`,
    # full green is at `1/3` and full blue at `2/3`.
    #
    # From the point in the range corresponding to the dominant
    # component, the delta of the other components are both added
    # in order to move the hue around this point.
    if r is v      then h = deltaB - deltaG
    else if g is v then h = (1 / 3) + deltaR - deltaB
    else if b == v then h = (2 / 3) + deltaG - deltaR

    # Hue is then reduced to fit in the `0-1` range.
    h += 1 if h < 0
    h -= 1 if h > 1

  # And, finally, hue, saturation and value are normalized
  # to their corresponding range.
  [h * 360, s * 100, v * 100]

# Public: Converts a color defined in the `hsv` color space into
# an {Array} containing the color in the `rgb` color space.
#
# h - An integer in the range [O-360] for the hue component
# s - A float in the range [O-100] for the saturation component
# v - A float in the range [O-100] for the value component
#
# Returns an {Array} containing the red, green and blue components
# of the color
hsvToRGB = (h, s, v) ->
  # Hue is reduced to the `0-6` range when both saturation
  # and value are reduced to the `0-1`
  h = h / 60
  s = s / 100
  v = v / 100
  rnd = Math.round

  # Short circuit when saturation is `0`, all other components
  # will end up to `0` as well.
  if s is 0
    return [rnd(v * 255), rnd(v * 255), rnd(v * 255)]
  else
    # By rounding the hue we obtain the dominant
    # color such as :
    #
    #  * 0 = Red
    #  * 1 = Yellow
    #  * 2 = Green
    #  * 3 = Cyan
    #  * 4 = Blue
    #  * 5 = Magenta
    dominant = Math.floor h

    comp1 = v * (1 - s)
    comp2 = v * (1 - s * (h - dominant))
    comp3 = v * (1 - s * (1 - (h - dominant)))

    # According to the dominant color we affect
    # the values to each component.
    switch dominant
      when 0 then [r, g, b] = [v, comp3, comp1]
      when 1 then [r, g, b] = [comp2, v, comp1]
      when 2 then [r, g, b] = [comp1, v, comp3]
      when 3 then [r, g, b] = [comp1, comp2, v]
      when 4 then [r, g, b] = [comp3, comp1, v]
      else        [r, g, b] = [v, comp1, comp2]

    # And each component is normalized to fit
    # in `0-255` range.
    return [r * 255, g * 255, b * 255]

# Public: Converts a color in the `rgb` color space in an
# {Array} with the color in the `hsl` color space.
#
# r - An integer in the range [O-255] for the red component
# g - An integer in the range [O-255] for the green component
# b - An integer in the range [O-255] for the blue component
#
# Returns an {Array} containing the hue, saturation and luminance of the color
rgbToHSL = (r, g, b) ->
  [r,g,b] = [
    r / 255
    g / 255
    b / 255
  ]
  max = Math.max(r, g, b)
  min = Math.min(r, g, b)
  h = undefined
  s = undefined
  l = (max + min) / 2
  d = max - min
  if max is min
    h = s = 0
  else
    s = (if l > 0.5 then d / (2 - max - min) else d / (max + min))
    switch max
      when r
        h = (g - b) / d + ((if g < b then 6 else 0))
      when g
        h = (b - r) / d + 2
      when b
        h = (r - g) / d + 4
    h /= 6

  [h * 360, s * 100, l * 100]

# Public: Converts a color defined in the `hsl` color space into
# an {Array} containing the color in the `rgb` color space.
#
# h - An integer in the range [O-360] for the hue component
# s - A float in the range [O-100] for the saturation component
# l - A float in the range [O-100] for the luminance component
#
# Returns an {Array} containing the red, green and blue components
# of the color
hslToRGB = (h, s, l) ->
  clamp = (val) -> Math.min 1, Math.max(0, val)

  hue = (h) ->
    h = (if h < 0 then h + 1 else ((if h > 1 then h - 1 else h)))
    if h * 6 < 1
      m1 + (m2 - m1) * h * 6
    else if h * 2 < 1
      m2
    else if h * 3 < 2
      m1 + (m2 - m1) * (2 / 3 - h) * 6
    else
      m1

  h = (h % 360) / 360
  s = clamp(s / 100)
  l = clamp(l / 100)
  m2 = (if l <= 0.5 then l * (s + 1) else l + s - l * s)
  m1 = l * 2 - m2

  return [
    hue(h + 1 / 3) * 255
    hue(h) * 255
    hue(h - 1 / 3) * 255
  ]

# Public: Converts a color from the `hsv` color space to the `hwb` one.
#
# h - The {Number} for the hue component.
# s - The {Number} for the saturation component.
# v - The {Number} for the value component.
#
# Returns an {Array} containing the hue, whiteness and blackness of the color.
hsvToHWB = (h, s, v) ->
  [s,v] = [s / 100, v / 100]

  w = (1 - s) * v
  b = 1 - v

  [h, w * 100, b * 100]

# Public: Converts a color from the `hwb` color space to the `hsv` one.
#
# h - The {Number} for the hue component.
# w - The {Number} for the whiteness component.
# b - The {Number} for the blackness component.
#
# Returns an {Array} with the hue, saturation and value of the color.
hwbToHSV = (h, w, b) ->
  [w,b] = [w / 100, b / 100]

  s = 1 - (w / (1 - b))
  v = 1 - b

  [h, s * 100, v * 100]

# Public: Converts a color in the `rgb` color space in an
# {Array} with the color in the `hwb` color space.
#
# r - An integer in the range [O-255] for the red component
# g - An integer in the range [O-255] for the green component
# b - An integer in the range [O-255] for the blue component
#
# Returns an {Array} containing the hue, whiteness and blackness
# of the color.
rgbToHWB = (r,g,b) -> hsvToHWB(rgbToHSV(r,g,b)...)

# Public: Converts a color defined in the `hwb` color space into
# an {Array} containing the color in the `rgb` color space.
#
# h - An integer {Number} in the range [O-360] for the hue component.
# w - A float {Number} in the range [O-100] for the whiteness component.
# b - A float {Number} in the range [O-100] for the blackness component.
#
# Returns an {Array} containing the red, green and blue components.
# of the color
hwbToRGB = (h,w,b) -> hsvToRGB(hwbToHSV(h,w,b)...)

# Public: Converts a color from the CMYK color space to the RGB color space
cmykToRGB = (c,m,y,k) ->
  r = 1 - Math.min(1, c * (1 - k) + k)
  g = 1 - Math.min(1, m * (1 - k) + k)
  b = 1 - Math.min(1, y * (1 - k) + k)

  r = Math.floor(r * 255)
  g = Math.floor(g * 255)
  b = Math.floor(b * 255)

  [r,g,b]


# Public: Converts a color from the RGB color space to the CMYK color space
rgbToCMYK = (r,g,b) ->
  # BLACK
  return [0, 0, 0, 1] if r == 0 and g == 0 and b == 0

  computedC = 1 - (r / 255)
  computedM = 1 - (g / 255)
  computedY = 1 - (b / 255)

  minCMY = Math.min(computedC, Math.min(computedM, computedY))

  computedC = (computedC - minCMY) / (1 - minCMY)
  computedM = (computedM - minCMY) / (1 - minCMY)
  computedY = (computedY - minCMY) / (1 - minCMY)
  computedK = minCMY

  [computedC, computedM, computedY, computedK]

module.exports = {
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
}
