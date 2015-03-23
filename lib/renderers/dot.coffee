
module.exports =
class DotRenderer
  render: (colorMarker) ->
    range = colorMarker.marker.getScreenRange()
    displayBuffer = colorMarker.marker.displayBuffer
    charWidth = displayBuffer.getDefaultCharWidth()

    markers = displayBuffer.findMarkers {
      type: 'pigments-color'
      intersectsScreenRowRange: [range.end.row, range.end.row]
    }

    index = markers.indexOf(colorMarker.marker)
    screenLine = displayBuffer.screenLines[range.end.row]

    column = (screenLine.getMaxScreenColumn() + 1) * charWidth
    pixelPosition = displayBuffer.pixelPositionForScreenPosition(range.end)

    class: 'dot'
    style:
      backgroundColor: colorMarker.color.toCSS()
      top: pixelPosition.top + 'px'
      left: (column + index * 18) + 'px'
