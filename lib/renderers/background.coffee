
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
    if rowSpan == 0
      regions.push @createRegion(1, range.start, range.end, color, colorText, colorMarker)
    else
      regions.push @createRegion(1, range.start, {row: range.start.row, column: Infinity}, color, colorText, colorMarker)
      if rowSpan > 1
        regions.push @createRegion(rowSpan - 1, { row: range.start.row + 1, column: 0}, {row: range.start.row + 1, column: Infinity}, color, colorText, colorMarker)
      regions.push @createRegion(1, { row: range.end.row, column: 0 }, range.end, color, colorText, colorMarker)

    regions

  createRegion: (rows, start, end, color, textColor, colorMarker) ->
    displayBuffer = colorMarker.marker.displayBuffer
    lineHeight = displayBuffer.getLineHeightInPixels()
    charWidth = displayBuffer.getDefaultCharWidth()

    bufferRange = displayBuffer.bufferRangeForScreenRange({start, end})
    text = displayBuffer.buffer.getTextInRange(bufferRange)

    css = displayBuffer.pixelPositionForScreenPosition(start)
    css.height = lineHeight * rows
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
