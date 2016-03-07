RegionRenderer = require './region-renderer'

module.exports =
class UnderlineRenderer extends RegionRenderer
  render: (colorMarker) ->
    color = colorMarker?.color
    return {} unless color?

    regions = @renderRegions(colorMarker)

    @styleRegion(region, color.toCSS()) for region in regions when region?
    {regions}

  styleRegion: (region, color) ->
    region.classList.add('underline')

    region.style.backgroundColor = color
