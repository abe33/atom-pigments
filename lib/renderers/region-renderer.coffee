
module.exports =
class RegionRenderer
  includeTextInRegion: false

  renderRegions: (colorMarker) ->
    range = colorMarker.getScreenRange()
    return [] if range.isEmpty()

    rowSpan = range.end.row - range.start.row
    regions = []

    textEditor = colorMarker.colorBuffer.editor

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
        @screenLineForScreenRow(textEditor, range.start.row)
      )
      if rowSpan > 1
        for row in [range.start.row + 1...range.end.row]
          regions.push @createRegion(
            {row, column: 0},
            {row, column: Infinity},
            colorMarker,
            @screenLineForScreenRow(textEditor, row)
          )

      regions.push @createRegion(
        {row: range.end.row, column: 0},
        range.end,
        colorMarker,
        @screenLineForScreenRow(textEditor, range.end.row)
      )

    regions

  screenLineForScreenRow: (textEditor, row) ->
    if textEditor.screenLineForScreenRow?
      textEditor.screenLineForScreenRow(row)
    else
      textEditor.displayBuffer.screenLines[row]

  createRegion: (start, end, colorMarker, screenLine) ->
    textEditor = colorMarker.colorBuffer.editor
    textEditorElement = atom.views.getView(textEditor)

    return unless textEditorElement.component?

    lineHeight = textEditor.getLineHeightInPixels()
    charWidth = textEditor.getDefaultCharWidth()

    clippedStart = {
      row: start.row
      column: @clipScreenColumn(screenLine, start.column) ? start.column
    }
    clippedEnd = {
      row: end.row
      column: @clipScreenColumn(screenLine, end.column) ? end.column
    }

    bufferRange = textEditor.bufferRangeForScreenRange({
      start: clippedStart
      end: clippedEnd
    })

    needAdjustment = screenLine?.isSoftWrapped?() and end.column >= screenLine?.text.length - screenLine?.softWrapIndentationDelta

    bufferRange.end.column++ if needAdjustment

    startPosition = textEditorElement.pixelPositionForScreenPosition(clippedStart)
    endPosition = textEditorElement.pixelPositionForScreenPosition(clippedEnd)

    text = textEditor.getBuffer().getTextInRange(bufferRange)

    css = {}
    css.left = startPosition.left
    css.top = startPosition.top
    css.width = endPosition.left - startPosition.left
    css.width += charWidth if needAdjustment
    css.height = lineHeight

    region = document.createElement('div')
    region.className = 'region'
    region.textContent = text if @includeTextInRegion
    region.invalid = true if startPosition.left is endPosition.left
    region.style[name] = value + 'px' for name, value of css

    region

  clipScreenColumn: (line, column) ->
    if line?
      if line.clipScreenColumn?
        line.clipScreenColumn(column)
      else
        Math.min(line.lineText.length, column)
