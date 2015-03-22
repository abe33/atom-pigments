RegionRenderer = require './region-renderer'

module.exports =
class UnderlineRenderer extends RegionRenderer
  render: (colorMarker) ->
    color = colorMarker.color.toCSS()
    regions = @renderRegions(colorMarker)

    @styleRegion(region, color) for region in regions
    {regions}

  styleRegion: (region, color) ->
    region.classList.add('underline')

    region.style.backgroundColor = color
