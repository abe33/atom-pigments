
module.exports =
class RegionRenderer
  includeTextInRegion: false

  renderRegions: (colorMarker) ->
    range = colorMarker.getScreenRange()
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
        displayBuffer.screenLines[range.start.row]
      )
      if rowSpan > 1
        for row in [range.start.row + 1...range.end.row]
          regions.push @createRegion(
            {row, column: 0},
            {row, column: Infinity},
            colorMarker,
            displayBuffer.screenLines[row]
          )

      regions.push @createRegion(
        {row: range.end.row, column: 0},
        range.end,
        colorMarker,
        displayBuffer.screenLines[range.end.row]
      )

    regions

  createRegion: (start, end, colorMarker, screenLine) ->
    textEditor = colorMarker.colorBuffer.editor
    textEditorElement = atom.views.getView(textEditor)
    displayBuffer = colorMarker.marker.displayBuffer

    lineHeight = textEditor.getLineHeightInPixels()
    charWidth = textEditor.getDefaultCharWidth()

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

    needAdjustment = screenLine?.isSoftWrapped() and end.column >= screenLine?.text.length - screenLine?.softWrapIndentationDelta

    bufferRange.end.column++ if needAdjustment

    startPosition = textEditorElement.pixelPositionForScreenPosition(clippedStart)
    endPosition = textEditorElement.pixelPositionForScreenPosition(clippedEnd)

    text = displayBuffer.buffer.getTextInRange(bufferRange)

    css = {}
    css.left = startPosition.left
    css.top = startPosition.top
    css.width = endPosition.left - startPosition.left
    css.width += charWidth if needAdjustment
    css.height = lineHeight

    region = document.createElement('div')
    region.className = 'region'

    if @includeTextInRegion
      region.textContent = text

    for name, value of css
      region.style[name] = value + 'px'

    region
