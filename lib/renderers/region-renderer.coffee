
module.exports =
class RegionRenderer
  includeTextInRegion: false

  renderRegions: (colorMarker) ->
    range = colorMarker.marker.getScreenRange()
    return [] if range.isEmpty()

    rowSpan = range.end.row - range.start.row
    regions = []

    displayBuffer = colorMarker.marker.displayBuffer

    if rowSpan is 0
      regions.push @createRegion(range.start, range.end, colorMarker)
    else
      screenLine = displayBuffer.screenLines[range.start.row]

      regions.push @createRegion(
        range.start,
        {
          row: range.start.row
          column: screenLine.clipScreenColumn(Infinity)
        },
        colorMarker,
        displayBuffer.screenLines[range.start.row + 1]
      )
      if rowSpan > 1
        for row in [range.start.row + 1...range.end.row]
          screenLine = displayBuffer.screenLines[range.start.row]

          regions.push @createRegion(
            {row, column: screenLine.clipScreenColumn(0)},
            {row, column: screenLine.clipScreenColumn(Infinity)},
            colorMarker,
            displayBuffer.screenLines[row + 1]
          )

      screenLine = displayBuffer.screenLines[range.end.row]
      regions.push @createRegion(
        {row: range.end.row, column: screenLine.clipScreenColumn(0)},
        range.end,
        colorMarker,
        displayBuffer.screenLines[range.end.row + 1]
      )

    regions

  createRegion: (start, end, colorMarker, nextScreenLine) ->
    displayBuffer = colorMarker.marker.displayBuffer
    lineHeight = displayBuffer.getLineHeightInPixels()
    charWidth = displayBuffer.getDefaultCharWidth()

    bufferRange = displayBuffer.bufferRangeForScreenRange({start, end})
    bufferRange.end.column++ if nextScreenLine?.isSoftWrapped()

    startPosition = displayBuffer.pixelPositionForScreenPosition(start)
    endPosition = displayBuffer.pixelPositionForScreenPosition(end)

    text = displayBuffer.buffer.getTextInRange(bufferRange)

    css = {}
    css.left = startPosition.left
    css.top = startPosition.top
    css.width = endPosition.left - startPosition.left
    css.width += charWidth if nextScreenLine?.isSoftWrapped()
    css.height = lineHeight

    region = document.createElement('div')
    region.className = 'region'

    if @includeTextInRegion
      region.textContent = text

    for name, value of css
      region.style[name] = value + 'px'

    region
