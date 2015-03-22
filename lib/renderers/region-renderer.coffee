
module.exports =
class RegionRenderer
  includeTextInRegion: false
  createRegion: (start, end, colorMarker) ->
    displayBuffer = colorMarker.marker.displayBuffer
    lineHeight = displayBuffer.getLineHeightInPixels()
    charWidth = displayBuffer.getDefaultCharWidth()

    bufferRange = displayBuffer.bufferRangeForScreenRange({start, end})

    css = displayBuffer.pixelPositionForScreenPosition(start)
    css.height = lineHeight
    if end
      css.width = displayBuffer.pixelPositionForScreenPosition(end).left - css.left
    else
      css.right = 0

    region = document.createElement('div')
    region.className = 'region'

    if @includeTextInRegion
      region.textContent = displayBuffer.buffer.getTextInRange(bufferRange)

    for name, value of css
      region.style[name] = value + 'px'

    region
