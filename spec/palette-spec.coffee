require './spec-helper'

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

  describe '::getColor', ->
    it 'returns the color with the given name', ->
      expect(palette.getColor('red')).toBeColor('#ff0000')

    it 'returns undefined if the name does not exist in this palette', ->
      expect(palette.getColor('foo')).toBeUndefined()

  describe '::getNames', ->
    it 'returns all the names a color have in the palette', ->
      expect(palette.getNames(new Color('#ff0000'))).toEqual(['red', 'redCopy'])
      expect(palette.getNames(new Color('#00ff00'))).toEqual(['green'])


  describe '::getUniqueColorsMap', ->
    it 'returns a Map that map colors to the variables that define them', ->
      expectedKeys = [
        new Color '#ff0000'
        new Color '#00ff00'
        new Color '#0000ff'
      ]
      map = palette.getUniqueColorsMap()
      keys = []
      map.forEach (v,k) -> keys.push(k)

      expect(keys.length).toEqual(3)

      expect(keys[i]).toBeColor(key) for key,i in expectedKeys

      expect(map.get(keys[0])).toEqual(['red', 'redCopy'])
      expect(map.get(keys[1])).toEqual(['green'])
      expect(map.get(keys[2])).toEqual(['blue'])

  describe '::sortedByName', ->
    it 'returns the colors and names sorted by name', ->
      expect(palette.sortedByName()).toEqual([
        ['blue', palette.getColor('blue')]
        ['green', palette.getColor('green')]
        ['red', palette.getColor('red')]
        ['redCopy', palette.getColor('redCopy')]
      ])

  describe '::sortedByColor', ->
    it 'returns the colors and names sorted by colors', ->
      expect(palette.sortedByColor()).toEqual([
        ['red', palette.getColor('red')]
        ['redCopy', palette.getColor('redCopy')]
        ['green', palette.getColor('green')]
        ['blue', palette.getColor('blue')]
      ])
