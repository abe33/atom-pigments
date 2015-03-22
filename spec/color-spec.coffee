require './spec-helper'

Color = require '../lib/color'

describe 'Color', ->
  [color] = []

  beforeEach ->
    color = new Color('#66ff6933')

  describe 'created with separated components', ->
    it 'creates the color with the provided components', ->
      expect(new Color(255, 127, 64, 0.5)).toBeColor(255, 127, 64, 0.5)

  describe 'created with a hexa rgb string', ->
    it 'creates the color with the provided components', ->
      expect(new Color('#ff6933')).toBeColor(255, 105, 51, 1)

  describe 'created with a hexa argb string', ->
    it 'creates the color with the provided components', ->
      expect(new Color('#66ff6933')).toBeColor(255, 105, 51, 0.4)

  describe 'created with the name of a svg color', ->
    it 'creates the color using its name', ->
      expect(new Color('orange')).toBeColor('#ffa500')

  describe '::isValid', ->
    it 'returns true when all the color components are valid', ->
      expect(new Color).toBeValid()

    it 'returns false when one component is NaN', ->
      expect(new Color NaN, 0, 0, 1).not.toBeValid()
      expect(new Color 0, NaN, 0, 1).not.toBeValid()
      expect(new Color 0, 0, NaN, 1).not.toBeValid()
      expect(new Color 0, 0, 1, NaN).not.toBeValid()

    it 'returns false when the color has the invalid flag', ->
      color = new Color
      color.invalid = true
      expect(color).not.toBeValid()

  describe '::rgb', ->
    it 'returns an array with the color components', ->
      expect(color.rgb).toBeComponentArrayCloseTo([
        color.red
        color.green
        color.blue
      ])

    it 'sets the color components based on the passed-in values', ->
      color.rgb = [1,2,3]

      expect(color).toBeColor(1,2,3,0.4)

  describe '::rgba', ->
    it 'returns an array with the color and alpha components', ->
      expect(color.rgba).toBeComponentArrayCloseTo([
        color.red
        color.green
        color.blue
        color.alpha
      ])

    it 'sets the color components based on the passed-in values', ->
      color.rgba = [1,2,3,0.7]

      expect(color).toBeColor(1,2,3,0.7)

  describe '::argb', ->
    it 'returns an array with the alpha and color components', ->
      expect(color.argb).toBeComponentArrayCloseTo([
        color.alpha
        color.red
        color.green
        color.blue
      ])

    it 'sets the color components based on the passed-in values', ->
      color.argb = [0.7,1,2,3]

      expect(color).toBeColor(1,2,3,0.7)

  describe '::hsv', ->
    it 'returns an array with the hue, saturation and value components', ->
      expect(color.hsv).toBeComponentArrayCloseTo([16, 80, 100])

    it 'sets the color components based on the passed-in values', ->
      color.hsv = [200,50,50]

      expect(color).toBeColor(64, 106, 128, 0.4)

  describe '::hsva', ->
    it 'returns an array with the hue, saturation, value and alpha components', ->
      expect(color.hsva).toBeComponentArrayCloseTo([16, 80, 100, 0.4])

    it 'sets the color components based on the passed-in values', ->
      color.hsva = [200,50,50,0.7]

      expect(color).toBeColor(64, 106, 128, 0.7)

  describe '::hsl', ->
    it 'returns an array with the hue, saturation and luminosity components', ->
      expect(color.hsl).toBeComponentArrayCloseTo([16, 100, 60])

    it 'sets the color components based on the passed-in values', ->
      color.hsl = [200,50,50]

      expect(color).toBeColor(64, 149, 191, 0.4)

  describe '::hsla', ->
    it 'returns an array with the hue, saturation, luminosity and alpha components', ->
      expect(color.hsla).toBeComponentArrayCloseTo([16, 100, 60, 0.4])

    it 'sets the color components based on the passed-in values', ->
      color.hsla = [200,50,50, 0.7]

      expect(color).toBeColor(64, 149, 191, 0.7)

  describe '::hwb', ->
    it 'returns an array with the hue, whiteness and blackness components', ->
      expect(color.hwb).toBeComponentArrayCloseTo([16, 20, 0])

    it 'sets the color components based on the passed-in values', ->
      color.hwb = [210,40,40]

      expect(color).toBeColor(102, 128, 153, 0.4)

  describe '::hwba', ->
    it 'returns an array with the hue, whiteness, blackness and alpha components', ->
      expect(color.hwba).toBeComponentArrayCloseTo([16, 20, 0, 0.4])

    it 'sets the color components based on the passed-in values', ->
      color.hwba = [210,40,40,0.7]

      expect(color).toBeColor(102, 128, 153, 0.7)

  describe '::hex', ->
    it 'returns the color as a hexadecimal string', ->
      expect(color.hex).toEqual('ff6933')

    it 'parses the string and sets the color components accordingly', ->
      color.hex = '00ff00'

      expect(color).toBeColor(0,255,0,0.4)

  describe '::hexARGB', ->
    it 'returns the color component as a hexadecimal string', ->
      expect(color.hexARGB).toEqual('66ff6933')

    it 'parses the string and sets the color components accordingly', ->
      color.hexARGB = 'ff00ff00'

      expect(color).toBeColor(0,255,0,1)

  describe '::hue', ->
    it 'returns the hue component', ->
      expect(color.hue).toEqual(color.hsl[0])

    it 'sets the hue component', ->
      color.hue = 20

      expect(color.hsl).toBeComponentArrayCloseTo([20, 100, 60])

  describe '::saturation', ->
    it 'returns the saturation component', ->
      expect(color.saturation).toEqual(color.hsl[1])

    it 'sets the saturation component', ->
      color.saturation = 20

      expect(color.hsl).toBeComponentArrayCloseTo([16, 20, 60])

  describe '::lightness', ->
    it 'returns the lightness component', ->
      expect(color.lightness).toEqual(color.hsl[2])

    it 'sets the lightness component', ->
      color.lightness = 20

      expect(color.hsl).toBeComponentArrayCloseTo([16, 100, 20])

  describe '::clone', ->
    it 'returns a copy of the current color', ->
      expect(color.clone()).toBeColor(color)
      expect(color.clone()).not.toBe(color)

  describe '::toCSS', ->
    describe 'when the color alpha channel is not 1', ->
      it 'returns the color as a rgba() color', ->
        expect(color.toCSS()).toEqual('rgba(255,105,51,0.4)')

    describe 'when the color alpha channel is 1', ->
      it 'returns the color as a rgb() color', ->
        color.alpha = 1
        expect(color.toCSS()).toEqual('rgb(255,105,51)')

    describe 'when the color have a CSS name', ->
      it 'only returns the color name', ->
        color = new Color 'orange'
        expect(color.toCSS()).toEqual('rgb(255,165,0)')

  describe '::interpolate', ->
    it 'blends the passed-in color linearly based on the passed-in ratio', ->
      colorA = new Color('#ff0000')
      colorB = new Color('#0000ff')
      colorC = colorA.interpolate(colorB, 0.5)

      expect(colorC).toBeColor('#7f007f')

  describe '::blend', ->
    it 'blends the passed-in color based on the passed-in blend function', ->
      colorA = new Color('#ff0000')
      colorB = new Color('#0000ff')
      colorC = colorA.blend colorB, (a,b) -> a / 2 + b / 2

      expect(colorC).toBeColor('#800080')

  describe '::transparentize', ->
    it 'returns a new color whose alpha is the passed-in value', ->
      expect(color.transparentize(1)).toBeColor(255,105,51,1)
      expect(color.transparentize(0.7)).toBeColor(255,105,51,0.7)
      expect(color.transparentize(0.1)).toBeColor(255,105,51,0.1)

  describe '::luma', ->
    it 'returns the luma value of the color', ->
      expect(color.luma).toBeCloseTo(0.31, 1)
