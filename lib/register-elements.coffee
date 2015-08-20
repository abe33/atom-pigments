ColorBuffer = require './color-buffer'
ColorSearch = require './color-search'
ColorProject = require './color-project'
Palette = require './palette'
ColorBufferElement = require './color-buffer-element'
ColorMarkerElement = require './color-marker-element'
ColorResultsElement = require './color-results-element'
ColorProjectElement = require './color-project-element'
PaletteElement = require './palette-element'

ColorBufferElement.registerViewProvider(ColorBuffer)
ColorResultsElement.registerViewProvider(ColorSearch)
ColorProjectElement.registerViewProvider(ColorProject)
PaletteElement.registerViewProvider(Palette)
