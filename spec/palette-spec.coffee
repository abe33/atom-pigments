Color = require '../lib/color'
Palette = require '../lib/palette'

describe 'Palette', ->
  [colors, palette] = []

  beforeEach ->
    colors =
      red: new Color '#ff0000'
      green: new Color '#00ff00'
      blue: new Color '#0000ff'
      redCopy: new Color '#ff0000'

    palette = new Palette(colors)

  describe '::getColorsCount', ->
    it 'returns the number of colors in the palette', ->
      expect(palette.getColorsCount()).toEqual(4)

  describe '::getColorsNames', ->
    it 'returns the names of the colors in the palette', ->
      expect(palette.getColorsNames()).toEqual([
        'red'
        'green'
        'blue'
        'redCopy'
      ])
