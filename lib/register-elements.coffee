ColorBuffer = require './color-buffer'
ColorSearch = require './color-search'
Palette = require './palette'
ColorBufferElement = require './color-buffer-element'
ColorMarkerElement = require './color-marker-element'
ColorResultsElement = require './color-results-element'
PaletteElement = require './palette-element'

ColorBufferElement.registerViewProvider(ColorBuffer)
ColorResultsElement.registerViewProvider(ColorSearch)
PaletteElement.registerViewProvider(Palette)
