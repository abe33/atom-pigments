RegionRenderer = require './region-renderer'

module.exports =
class OutlineRenderer extends RegionRenderer
  render: (colorMarker) ->
    range = colorMarker.marker.getScreenRange()
    return [] if range.isEmpty()

    color = colorMarker.color.toCSS()

    style =
      webkitFilter: "drop-shadow(0 0 1px #{color}) drop-shadow(0 0 1px #{color}) drop-shadow(0 0 1px #{color}) drop-shadow(0 0 1px #{color})"

    rowSpan = range.end.row - range.start.row
    regions = @renderRegions(colorMarker)

    @styleRegion(region) for region in regions
    {regions, style}

  styleRegion: (region) ->
    region.classList.add('outline')
