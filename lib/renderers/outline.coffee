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
    regions = []
    if rowSpan is 0
      regions.push @createRegion(range.start, range.end, colorMarker)
    else
      regions.push @createRegion(range.start, {row: range.start.row, column: Infinity}, colorMarker)
      if rowSpan > 1
        for row in [range.start.row + 1...range.end.row]
          regions.push @createRegion({row, column: 0}, {row, column: Infinity}, colorMarker)

      regions.push @createRegion({ row: range.end.row, column: 0 }, range.end, colorMarker)

    @styleRegion(region) for region in regions
    {regions, style}

  styleRegion: (region) ->
    region.classList.add('outline')
