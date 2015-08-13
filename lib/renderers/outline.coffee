RegionRenderer = require './region-renderer'

module.exports =
class OutlineRenderer extends RegionRenderer
  render: (colorMarker) ->
    range = colorMarker.getScreenRange()
    return [] if range.isEmpty()

    color = colorMarker.color.toCSS()

    rowSpan = range.end.row - range.start.row
    regions = @renderRegions(colorMarker)

    @styleRegion(region, color) for region in regions
    {regions}

  styleRegion: (region, color) ->
    region.classList.add('outline')
    region.style.borderColor = color
