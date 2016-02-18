
module.exports =
class DotRenderer
  render: (colorMarker) ->
    range = colorMarker.getScreenRange()

    color = colorMarker.color

    return {} unless color?

    textEditor = colorMarker.colorBuffer.editor
    textEditorElement = atom.views.getView(textEditor)
    displayBuffer = colorMarker.marker.displayBuffer
    charWidth = displayBuffer.getDefaultCharWidth()

    markers = colorMarker.colorBuffer.getMarkerLayer().findMarkers {
      type: 'pigments-color'
      intersectsScreenRowRange: [range.end.row, range.end.row]
    }

    index = markers.indexOf(colorMarker.marker)
    screenLine = displayBuffer.screenLines[range.end.row]

    return {} unless screenLine?

    lineHeight = textEditor.getLineHeightInPixels()
    column = (screenLine.getMaxScreenColumn() + 1) * charWidth
    pixelPosition = textEditorElement.pixelPositionForScreenPosition(range.end)

    class: 'dot'
    style:
      backgroundColor: color.toCSS()
      top: (pixelPosition.top + lineHeight / 2) + 'px'
      left: (column + index * 18) + 'px'
