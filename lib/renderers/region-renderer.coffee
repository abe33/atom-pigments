
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
      regions.push @createRegion(
        range.start,
        {
          row: range.start.row
          column: Infinity
        },
        colorMarker,
        displayBuffer.screenLines[range.start.row],
        displayBuffer.screenLines[range.start.row + 1]
      )
      if rowSpan > 1
        for row in [range.start.row + 1...range.end.row]
          regions.push @createRegion(
            {row, column: 0},
            {row, column: Infinity},
            colorMarker,
            displayBuffer.screenLines[row],
            displayBuffer.screenLines[row + 1]
          )

      regions.push @createRegion(
        {row: range.end.row, column: 0},
        range.end,
        colorMarker,
        displayBuffer.screenLines[range.end.row],
        displayBuffer.screenLines[range.end.row + 1]
      )

    regions

  createRegion: (start, end, colorMarker, screenLine, nextScreenLine) ->
    displayBuffer = colorMarker.marker.displayBuffer
    lineHeight = displayBuffer.getLineHeightInPixels()
    charWidth = displayBuffer.getDefaultCharWidth()

    clippedStart = {
      row: start.row
      column: screenLine?.clipScreenColumn(start.column) ? start.column
    }
    clippedEnd = {
      row: end.row
      column: screenLine?.clipScreenColumn(end.column) ? end.column
    }

    bufferRange = displayBuffer.bufferRangeForScreenRange({
      start: clippedStart
      end: clippedEnd
    })

    if nextScreenLine?.isSoftWrapped() and end.column is Infinity
      bufferRange.end.column++

    startPosition = displayBuffer.pixelPositionForScreenPosition(clippedStart)
    endPosition = displayBuffer.pixelPositionForScreenPosition(clippedEnd)

    text = displayBuffer.buffer.getTextInRange(bufferRange)

    css = {}
    css.left = startPosition.left
    css.top = startPosition.top
    css.width = endPosition.left - startPosition.left
    css.width += charWidth if nextScreenLine?.isSoftWrapped() and end.column is Infinity
    css.height = lineHeight

    region = document.createElement('div')
    region.className = 'region'

    if @includeTextInRegion
      region.textContent = text

    for name, value of css
      region.style[name] = value + 'px'

    region
