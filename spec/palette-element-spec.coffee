Color = require '../lib/color'
Palette = require '../lib/palette'

fdescribe 'PaletteElement', ->
  [palette, paletteElement] = []

  beforeEach ->
    palette = new Palette
      red: new Color '#ff0000'
      green: new Color '#00ff00'
      blue: new Color '#0000ff'
      redCopy: new Color '#ff0000'

    paletteElement = atom.views.getView(palette)

  it 'is associated with the Palette model', ->
    expect(paletteElement).toBeDefined()
