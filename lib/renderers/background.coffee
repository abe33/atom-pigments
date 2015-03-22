
module.exports =
class BackgroundRenderer
  render: (colorMarker) ->
    range = colorMarker.marker.getScreenRange()
    return [] if range.isEmpty()

    color = colorMarker.color.toCSS()

    l = colorMarker.color.luma

    colorText = if l > 0.43 then 'black' else 'white'

    rowSpan = range.end.row - range.start.row
    regions = []
    if rowSpan is 0
      regions.push @createRegion(range.start, range.end, color, colorText, colorMarker)
    else
      regions.push @createRegion(range.start, {row: range.start.row, column: Infinity}, color, colorText, colorMarker)
      if rowSpan > 1
        for row in [range.start.row + 1...range.end.row]
          regions.push @createRegion({row, column: 0}, {row, column: Infinity}, color, colorText, colorMarker)

      regions.push @createRegion({ row: range.end.row, column: 0 }, range.end, color, colorText, colorMarker)

    regions

  createRegion: (start, end, color, textColor, colorMarker) ->
    displayBuffer = colorMarker.marker.displayBuffer
    lineHeight = displayBuffer.getLineHeightInPixels()
    charWidth = displayBuffer.getDefaultCharWidth()

    bufferRange = displayBuffer.bufferRangeForScreenRange({start, end})
    text = displayBuffer.buffer.getTextInRange(bufferRange)

    css = displayBuffer.pixelPositionForScreenPosition(start)
    css.height = lineHeight
    if end
      css.width = displayBuffer.pixelPositionForScreenPosition(end).left - css.left
    else
      css.right = 0

    region = document.createElement('div')
    region.className = 'region background'
    region.textContent = text
    for name, value of css
      region.style[name] = value + 'px'

    region.style.backgroundColor = color
    region.style.color = textColor

    region
