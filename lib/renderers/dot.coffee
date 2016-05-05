
module.exports =
class DotRenderer
  render: (colorMarker) ->
    range = colorMarker.getScreenRange()

    color = colorMarker.color

    return {} unless color?

    textEditor = colorMarker.colorBuffer.editor
    textEditorElement = atom.views.getView(textEditor)
    charWidth = textEditor.getDefaultCharWidth()

    markers = colorMarker.colorBuffer.getMarkerLayer().findMarkers {
      type: 'pigments-color'
      intersectsScreenRowRange: [range.end.row, range.end.row]
    }

    index = markers.indexOf(colorMarker.marker)
    screenLine = @screenLineForScreenRow(textEditor, range.end.row)

    return {} unless screenLine?

    lineHeight = textEditor.getLineHeightInPixels()
    column = @getLineLastColumn(screenLine) * charWidth
    pixelPosition = textEditorElement.pixelPositionForScreenPosition(range.end)

    class: 'dot'
    style:
      backgroundColor: color.toCSS()
      top: (pixelPosition.top + lineHeight / 2) + 'px'
      left: (column + index * 18) + 'px'

  getLineLastColumn: (line) ->
    if line.lineText?
      line.lineText.length + 1
    else
      line.getMaxScreenColumn() + 1

  screenLineForScreenRow: (textEditor, row) ->
    if textEditor.screenLineForScreenRow?
      textEditor.screenLineForScreenRow(row)
    else
      textEditor.displayBuffer.screenLines[row]
