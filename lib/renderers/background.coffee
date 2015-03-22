RegionRenderer = require './region-renderer'

module.exports =
class BackgroundRenderer extends RegionRenderer
  includeTextInRegion: true
  render: (colorMarker) ->

    color = colorMarker.color.toCSS()

    regions = @renderRegions(colorMarker)

    l = colorMarker.color.luma

    colorText = if l > 0.43 then 'black' else 'white'
    @styleRegion(region, color, colorText) for region in regions
    {regions}

  styleRegion: (region, color, textColor) ->
    region.classList.add('background')

    region.style.backgroundColor = color
    region.style.color = textColor
