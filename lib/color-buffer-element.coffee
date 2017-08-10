
{registerOrUpdateElement, EventsDelegation} = require 'atom-utils'

[Emitter, CompositeDisposable] = []

nextHighlightId = 0

class ColorBufferElement extends HTMLElement
  EventsDelegation.includeInto(this)

  createdCallback: ->
    unless Emitter?
      {Emitter, CompositeDisposable} = require 'atom'

    [@editorScrollLeft, @editorScrollTop] = [0, 0]
    @emitter = new Emitter
    @subscriptions = new CompositeDisposable
    @displayedMarkers = []
    @usedMarkers = []
    @unusedMarkers = []
    @viewsByMarkers = new WeakMap

  attachedCallback: ->
    @attached = true
    @update()

  detachedCallback: ->
    @attached = false

  onDidUpdate: (callback) ->
    @emitter.on 'did-update', callback

  getModel: -> @colorBuffer

  setModel: (@colorBuffer) ->
    {@editor} = @colorBuffer
    return if @editor.isDestroyed()
    @editorElement = atom.views.getView(@editor)

    @colorBuffer.initialize().then => @update()

    @subscriptions.add @colorBuffer.onDidUpdateColorMarkers => @update()
    @subscriptions.add @colorBuffer.onDidDestroy => @destroy()

    @subscriptions.add @editor.onDidChange =>
      @usedMarkers.forEach (marker) ->
        marker.colorMarker?.invalidateScreenRangeCache()
        marker.checkScreenRange()

    @subscriptions.add @editor.onDidAddCursor =>
      @requestSelectionUpdate()
    @subscriptions.add @editor.onDidRemoveCursor =>
      @requestSelectionUpdate()
    @subscriptions.add @editor.onDidChangeCursorPosition =>
      @requestSelectionUpdate()
    @subscriptions.add @editor.onDidAddSelection =>
      @requestSelectionUpdate()
    @subscriptions.add @editor.onDidRemoveSelection =>
      @requestSelectionUpdate()
    @subscriptions.add @editor.onDidChangeSelectionRange =>
      @requestSelectionUpdate()

    @subscriptions.add atom.config.observe 'pigments.maxDecorationsInGutter', =>
      @update()

    @subscriptions.add atom.config.observe 'pigments.markerType', (type) =>
      @initializeNativeDecorations(type)
      @previousType = type

    @subscriptions.add @editorElement.onDidAttach => @attach()
    @subscriptions.add @editorElement.onDidDetach => @detach()

  attach: ->
    return if @parentNode?
    return unless @editorElement?
    @getEditorRoot().querySelector('.lines')?.appendChild(this)

  detach: ->
    return unless @parentNode?

    @parentNode.removeChild(this)

  destroy: ->
    @detach()
    @subscriptions.dispose()
    @destroyNativeDecorations()

    @colorBuffer = null

  update: ->
    if @isGutterType()
      @updateGutterDecorations()
    else
      @updateHighlightDecorations(@previousType)

  getEditorRoot: -> @editorElement

  isGutterType: (type=@previousType) ->
    type in ['gutter', 'native-dot', 'native-square-dot']

  isDotType:  (type=@previousType) ->
    type in ['native-dot', 'native-square-dot']

  initializeNativeDecorations: (type) ->
    @destroyNativeDecorations()

    if @isGutterType(type)
      @initializeGutter(type)
    else
      @updateHighlightDecorations(type)

  destroyNativeDecorations: ->
    if @isGutterType()
      @destroyGutter()
    else
      @destroyHighlightDecorations()

  ##   ##     ## ##  ######   ##     ## ##       ##  ######   ##     ## ########
  ##   ##     ## ## ##    ##  ##     ## ##       ## ##    ##  ##     ##    ##
  ##   ##     ## ## ##        ##     ## ##       ## ##        ##     ##    ##
  ##   ######### ## ##   #### ######### ##       ## ##   #### #########    ##
  ##   ##     ## ## ##    ##  ##     ## ##       ## ##    ##  ##     ##    ##
  ##   ##     ## ## ##    ##  ##     ## ##       ## ##    ##  ##     ##    ##
  ##   ##     ## ##  ######   ##     ## ######## ##  ######   ##     ##    ##

  updateHighlightDecorations: (type) ->
    return if @editor.isDestroyed()

    @styleByMarkerId ?= {}
    @decorationByMarkerId ?= {}

    markers = @colorBuffer.getValidColorMarkers()

    for m in @displayedMarkers when m not in markers
      @decorationByMarkerId[m.id]?.destroy()
      @removeChild(@styleByMarkerId[m.id])
      delete @styleByMarkerId[m.id]
      delete @decorationByMarkerId[m.id]

    markersByRows = {}
    maxRowLength = 0

    for m in markers
      if m.color?.isValid() and m not in @displayedMarkers
        {className, style} = @getHighlighDecorationCSS(m, type)
        @appendChild(style)
        @styleByMarkerId[m.id] = style
        if type is 'native-background'
          @decorationByMarkerId[m.id] = @editor.decorateMarker(m.marker, {
            type: 'text'
            class: "pigments-#{type} #{className}"
          })
        else
          @decorationByMarkerId[m.id] = @editor.decorateMarker(m.marker, {
            type: 'highlight'
            class: "pigments-#{type} #{className}"
          })

    @displayedMarkers = markers
    @emitter.emit 'did-update'

  destroyHighlightDecorations: ->
    for id, deco of @decorationByMarkerId
      @removeChild(@styleByMarkerId[id]) if @styleByMarkerId[id]?
      deco.destroy()

    delete @decorationByMarkerId
    delete @styleByMarkerId
    @displayedMarkers = []

  getHighlighDecorationCSS: (marker, type) ->
    className = "pigments-highlight-#{nextHighlightId++}"
    style = document.createElement('style')
    l = marker.color.luma

    if type is 'native-background'
      style.innerHTML = """
      .#{className} {
        background-color: #{marker.color.toCSS()};
        background-image:
          linear-gradient(to bottom, #{marker.color.toCSS()} 0%, #{marker.color.toCSS()} 100%),
          url(atom://pigments/resources/transparent-background.png);
        color: #{if l > 0.43 then 'black' else 'white'};
      }
      """
    else if type is 'native-underline'
      style.innerHTML = """
      .#{className} .region {
        background-color: #{marker.color.toCSS()};
        background-image:
          linear-gradient(to bottom, #{marker.color.toCSS()} 0%, #{marker.color.toCSS()} 100%),
          url(atom://pigments/resources/transparent-background.png);
      }
      """
    else if type is 'native-outline'
      style.innerHTML = """
      .#{className} .region {
        border-color: #{marker.color.toCSS()};
      }
      """

    {className, style}

  ##     ######   ##     ## ######## ######## ######## ########
  ##    ##    ##  ##     ##    ##       ##    ##       ##     ##
  ##    ##        ##     ##    ##       ##    ##       ##     ##
  ##    ##   #### ##     ##    ##       ##    ######   ########
  ##    ##    ##  ##     ##    ##       ##    ##       ##   ##
  ##    ##    ##  ##     ##    ##       ##    ##       ##    ##
  ##     ######    #######     ##       ##    ######## ##     ##

  initializeGutter: (type) ->
    options = name: "pigments-#{type}"
    options.priority = 1000 if type isnt 'gutter'

    @gutter = @editor.addGutter(options)
    @displayedMarkers = []
    @decorationByMarkerId ?= {}
    gutterContainer = @getEditorRoot().querySelector('.gutter-container')
    @gutterSubscription = new CompositeDisposable

    @gutterSubscription.add @subscribeTo gutterContainer,
      mousedown: (e) =>
        targetDecoration = e.path[0]

        unless targetDecoration.matches('span')
          targetDecoration = targetDecoration.querySelector('span')

        return unless targetDecoration?

        markerId = targetDecoration.dataset.markerId
        colorMarker = @displayedMarkers.filter((m) -> m.id is Number(markerId))[0]

        return unless colorMarker? and @colorBuffer?

        @colorBuffer.selectColorMarkerAndOpenPicker(colorMarker)

    if @isDotType(type)
      @gutterSubscription.add @editorElement.onDidChangeScrollLeft =>
        requestAnimationFrame =>
          @updateDotDecorationsOffsets(@editorElement.getFirstVisibleScreenRow(), @editorElement.getLastVisibleScreenRow())

      @gutterSubscription.add @editorElement.onDidChangeScrollTop =>
        requestAnimationFrame =>
          @updateDotDecorationsOffsets(@editorElement.getFirstVisibleScreenRow(), @editorElement.getLastVisibleScreenRow())

      @gutterSubscription.add @editor.onDidChange (changes) =>
        if Array.isArray changes
          changes?.forEach (change) =>
            @updateDotDecorationsOffsets(change.start.row, change.newExtent.row)

        else if changes.start? and changes.newExtent?
          @updateDotDecorationsOffsets(changes.start.row, changes.newExtent.row)

    @updateGutterDecorations(type)

  destroyGutter: ->
    try @gutter.destroy()
    @gutterSubscription.dispose()
    @displayedMarkers = []
    decoration.destroy() for id, decoration of @decorationByMarkerId
    delete @decorationByMarkerId
    delete @gutterSubscription

  updateGutterDecorations: (type=@previousType) ->
    return if @editor.isDestroyed()

    markers = @colorBuffer.getValidColorMarkers()

    for m in @displayedMarkers when m not in markers
      @decorationByMarkerId[m.id]?.destroy()
      delete @decorationByMarkerId[m.id]

    markersByRows = {}
    maxRowLength = 0
    scrollLeft = @editorElement.getScrollLeft()
    maxDecorationsInGutter = atom.config.get('pigments.maxDecorationsInGutter')

    for m in markers
      if m.color?.isValid() and m not in @displayedMarkers
        @decorationByMarkerId[m.id] = @gutter.decorateMarker(m.marker, {
          type: 'gutter'
          class: 'pigments-gutter-marker'
          item: @getGutterDecorationItem(m)
        })

      deco = @decorationByMarkerId[m.id]
      row = m.marker.getStartScreenPosition().row
      markersByRows[row] ?= 0

      continue if markersByRows[row] >= maxDecorationsInGutter

      rowLength = 0

      if type isnt 'gutter'
        try
          rowLength = @editorElement.pixelPositionForScreenPosition([row, Infinity]).left

      decoWidth = 14

      deco.properties.item.style.left = "#{(rowLength + markersByRows[row] * decoWidth) - scrollLeft}px"

      markersByRows[row]++
      maxRowLength = Math.max(maxRowLength, markersByRows[row])

    if type is 'gutter'
      atom.views.getView(@gutter).style.minWidth = "#{maxRowLength * decoWidth}px"
    else
      atom.views.getView(@gutter).style.width = "0px"

    @displayedMarkers = markers
    @emitter.emit 'did-update'

  updateDotDecorationsOffsets: (rowStart, rowEnd) ->
    markersByRows = {}
    scrollLeft = @editorElement.getScrollLeft()

    for row in [rowStart..rowEnd]
      for m in @displayedMarkers
        deco = @decorationByMarkerId[m.id]
        continue unless m.marker?
        markerRow = m.marker.getStartScreenPosition().row
        continue unless row is markerRow

        markersByRows[row] ?= 0

        rowLength = @editorElement.pixelPositionForScreenPosition([row, Infinity]).left

        decoWidth = 14

        deco.properties.item.style.left = "#{(rowLength + markersByRows[row] * decoWidth) - scrollLeft}px"
        markersByRows[row]++

  getGutterDecorationItem: (marker) ->
    div = document.createElement('div')
    div.innerHTML = """
    <span style='background-image: linear-gradient(to bottom, #{marker.color.toCSS()} 0%, #{marker.color.toCSS()} 100%), url(atom://pigments/resources/transparent-background.png);' data-marker-id='#{marker.id}'></span>
    """
    div

  ##     ######  ######## ##       ########  ######  ########
  ##    ##    ## ##       ##       ##       ##    ##    ##
  ##    ##       ##       ##       ##       ##          ##
  ##     ######  ######   ##       ######   ##          ##
  ##          ## ##       ##       ##       ##          ##
  ##    ##    ## ##       ##       ##       ##    ##    ##
  ##     ######  ######## ######## ########  ######     ##

  requestSelectionUpdate: ->
    return if @updateRequested

    @updateRequested = true
    requestAnimationFrame =>
      @updateRequested = false
      return if @editor.getBuffer().isDestroyed()
      @updateSelections()

  updateSelections: ->
    return if @editor.isDestroyed()
    for marker in @displayedMarkers
      decoration = @decorationByMarkerId[marker.id]

      @hideDecorationIfInSelection(marker, decoration) if decoration?

  hideDecorationIfInSelection: (marker, decoration) ->
    selections = @editor.getSelections()

    props = decoration.getProperties()
    classes = props.class.split(/\s+/g)

    for selection in selections
      range = selection.getScreenRange()
      markerRange = marker.getScreenRange()

      continue unless markerRange? and range?
      if markerRange.intersectsWith(range)
        classes[0] += '-in-selection' unless classes[0].match(/-in-selection$/)?
        props.class = classes.join(' ')
        decoration.setProperties(props)
        return

    classes = classes.map (cls) -> cls.replace('-in-selection', '')
    props.class = classes.join(' ')
    decoration.setProperties(props)

  hideMarkerIfInSelectionOrFold: (marker, view) ->
    selections = @editor.getSelections()

    for selection in selections
      range = selection.getScreenRange()
      markerRange = marker.getScreenRange()

      continue unless markerRange? and range?

      view.classList.add('hidden') if markerRange.intersectsWith(range)
      view.classList.add('in-fold') if  @editor.isFoldedAtBufferRow(marker.getBufferRange().start.row)

  ##     ######   #######  ##    ## ######## ######## ##     ## ########
  ##    ##    ## ##     ## ###   ##    ##    ##        ##   ##     ##
  ##    ##       ##     ## ####  ##    ##    ##         ## ##      ##
  ##    ##       ##     ## ## ## ##    ##    ######      ###       ##
  ##    ##       ##     ## ##  ####    ##    ##         ## ##      ##
  ##    ##    ## ##     ## ##   ###    ##    ##        ##   ##     ##
  ##     ######   #######  ##    ##    ##    ######## ##     ##    ##
  ##
  ##    ##     ## ######## ##    ## ##     ##
  ##    ###   ### ##       ###   ## ##     ##
  ##    #### #### ##       ####  ## ##     ##
  ##    ## ### ## ######   ## ## ## ##     ##
  ##    ##     ## ##       ##  #### ##     ##
  ##    ##     ## ##       ##   ### ##     ##
  ##    ##     ## ######## ##    ##  #######

  colorMarkerForMouseEvent: (event) ->
    position = @screenPositionForMouseEvent(event)

    return unless position?

    bufferPosition = @colorBuffer.editor.bufferPositionForScreenPosition(position)

    @colorBuffer.getColorMarkerAtBufferPosition(bufferPosition)

  screenPositionForMouseEvent: (event) ->
    pixelPosition = @pixelPositionForMouseEvent(event)

    return unless pixelPosition?

    if @editorElement.screenPositionForPixelPosition?
      @editorElement.screenPositionForPixelPosition(pixelPosition)
    else
      @editor.screenPositionForPixelPosition(pixelPosition)

  pixelPositionForMouseEvent: (event) ->
    {clientX, clientY} = event

    scrollTarget = if @editorElement.getScrollTop?
      @editorElement
    else
      @editor

    rootElement = @getEditorRoot()

    return unless rootElement.querySelector('.lines')?

    {top, left} = rootElement.querySelector('.lines').getBoundingClientRect()
    top = clientY - top + scrollTarget.getScrollTop()
    left = clientX - left + scrollTarget.getScrollLeft()
    {top, left}

module.exports =
ColorBufferElement =
registerOrUpdateElement 'pigments-markers', ColorBufferElement.prototype
