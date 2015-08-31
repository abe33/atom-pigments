require './spec-helper'

Color = require '../lib/color'
Palette = require '../lib/palette'

describe 'Palette', ->
  [palette, colors] = []

  createVar = (name, color, path, line) ->
    {name, color, path, line}

  beforeEach ->
    colors = [
      createVar 'red', new Color('#ff0000'), 'file.styl', 0
      createVar 'green', new Color('#00ff00'), 'file.styl', 1
      createVar 'blue', new Color('#0000ff'), 'file.styl', 2
      createVar 'redCopy', new Color('#ff0000'), 'file.styl', 3
      createVar 'red', new Color('#ff0000'), 'file2.styl', 0
    ]
    palette = new Palette(colors)

  describe '::getColorsCount', ->
    it 'returns the number of colors in the palette', ->
      expect(palette.getColorsCount()).toEqual(5)

  describe '::getColorsNames', ->
    it 'returns the names of the colors in the palette', ->
      expect(palette.getColorsNames()).toEqual([
        'red'
        'green'
        'blue'
        'redCopy'
        'red'
      ])

  describe '::sortedByName', ->
    it 'returns the colors and names sorted by name', ->
      expect(palette.sortedByName()).toEqual([
        colors[2]
        colors[1]
        colors[0]
        colors[4]
        colors[3]
      ])

  describe '::sortedByColor', ->
    it 'returns the colors and names sorted by colors', ->
      expect(palette.sortedByColor()).toEqual([
        colors[0]
        colors[3]
        colors[4]
        colors[1]
        colors[2]
      ])
