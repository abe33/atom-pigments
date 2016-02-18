RegionRenderer = require './region-renderer'

module.exports =
class OutlineRenderer extends RegionRenderer
  render: (colorMarker) ->
    range = colorMarker.getScreenRange()
    color = colorMarker.color
    return {} if range.isEmpty() or not color?

    rowSpan = range.end.row - range.start.row
    regions = @renderRegions(colorMarker)

    @styleRegion(region, color.toCSS()) for region in regions
    {regions}

  styleRegion: (region, color) ->
    region.classList.add('outline')
    region.style.borderColor = color
