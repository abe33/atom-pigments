{Emitter, CompositeDisposable} = require 'atom'
{registerOrUpdateElement, EventsDelegation} = require 'atom-utils'
ColorMarkerElement = require './color-marker-element'

class ColorBufferElement extends HTMLElement
  EventsDelegation.includeInto(this)

  createdCallback: ->
    [@editorScrollLeft, @editorScrollTop] = [0, 0]
    @emitter = new Emitter
    @subscriptions = new CompositeDisposable
    @shadowRoot = @createShadowRoot()
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

    scrollLeftListener = (@editorScrollLeft) => @updateScroll()
    scrollTopListener = (@editorScrollTop) =>
      return if @useGutter()
      @updateScroll()
      requestAnimationFrame => @updateMarkers()

    if @editorElement.onDidChangeScrollLeft?
      @subscriptions.add @editorElement.onDidChangeScrollLeft(scrollLeftListener)
      @subscriptions.add @editorElement.onDidChangeScrollTop(scrollTopListener)
    else
      @subscriptions.add @editor.onDidChangeScrollLeft(scrollLeftListener)
      @subscriptions.add @editor.onDidChangeScrollTop(scrollTopListener)

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

    if @editor.onDidTokenize?
      @subscriptions.add @editor.onDidTokenize => @editorConfigChanged()
    else
      @subscriptions.add @editor.displayBuffer.onDidTokenize =>
        @editorConfigChanged()

    @subscriptions.add atom.config.observe 'editor.fontSize', =>
      @editorConfigChanged()

    @subscriptions.add atom.config.observe 'editor.lineHeight', =>
      @editorConfigChanged()

    @subscriptions.add atom.config.observe 'pigments.markerType', (type) =>
      switch type
        when 'gutter'
          @releaseAllMarkerViews()
          @initializeGutter()
        when 'background'
          @classList.add('above-editor-content')
          @destroyGutter() if @previousType is 'gutter'
        else
          @classList.remove('above-editor-content')
          @destroyGutter() if @previousType is 'gutter'

      @previousType = type

    @subscriptions.add atom.styles.onDidAddStyleElement =>
      @editorConfigChanged()

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
    @releaseAllMarkerViews()
    @colorBuffer = null

  update: ->
    if @useGutter()
      @updateGutterDecorations()
    else
      @updateMarkers()

  updateScroll: ->
    if @editorElement.hasTiledRendering and not @useGutter()
      @style.webkitTransform = "translate3d(#{-@editorScrollLeft}px, #{-@editorScrollTop}px, 0)"

  getEditorRoot: -> @editorElement.shadowRoot ? @editorElement

  editorConfigChanged: ->
    return if not @parentNode? or @useGutter()
    @usedMarkers.forEach (marker) =>
      if marker.colorMarker?
        marker.render()
      else
        console.warn "A marker view was found in the used instance pool while having a null model", marker
        @releaseMarkerElement(marker)

    @updateMarkers()

  ##     ######   ##     ## ######## ######## ######## ########
  ##    ##    ##  ##     ##    ##       ##    ##       ##     ##
  ##    ##        ##     ##    ##       ##    ##       ##     ##
  ##    ##   #### ##     ##    ##       ##    ######   ########
  ##    ##    ##  ##     ##    ##       ##    ##       ##   ##
  ##    ##    ##  ##     ##    ##       ##    ##       ##    ##
  ##     ######    #######     ##       ##    ######## ##     ##

  useGutter: -> @previousType is 'gutter'

  initializeGutter: ->
    @gutter = @editor.addGutter name: 'pigments'
    @displayedMarkers = []
    @decorationByMarkerId = {}
    gutterContainer = @getEditorRoot().querySelector('.gutter-container')
    @gutterSubscription = @subscribeTo gutterContainer,
      mousedown: (e) =>
        targetDecoration = e.path[0]

        unless targetDecoration.matches('span')
          targetDecoration = targetDecoration.querySelector('span')

        return unless targetDecoration?

        markerId = targetDecoration.dataset.markerId
        colorMarker = @displayedMarkers.filter((m) -> m.id is Number(markerId))[0]

        return unless colorMarker? and @colorBuffer?

        @colorBuffer.selectColorMarkerAndOpenPicker(colorMarker)

    @updateGutterDecorations()

  destroyGutter: ->
    @gutter.destroy()
    @gutterSubscription.dispose()
    @displayedMarkers = []
    decoration.destroy() for id, decoration of @decorationByMarkerId
    @decorationByMarkerId = null
    @gutterSubscription = null
    @updateMarkers()

  updateGutterDecorations: ->
    return if @editor.isDestroyed()

    markers = @colorBuffer.getValidColorMarkers()

    for m in @displayedMarkers when m not in markers
      @decorationByMarkerId[m.id]?.destroy()
      delete @decorationByMarkerId[m.id]

    markersByRows = {}
    maxRowLength = 0

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

      deco.properties.item.style.left = "#{markersByRows[row] * 14}px"

      markersByRows[row]++
      maxRowLength = Math.max(maxRowLength, markersByRows[row])

    atom.views.getView(@gutter).style.minWidth = "#{maxRowLength * 14}px"

    @displayedMarkers = markers
    @emitter.emit 'did-update'

  getGutterDecorationItem: (marker) ->
    div = document.createElement('div')
    div.innerHTML = """
    <span style='background-color: #{marker.color.toCSS()};' data-marker-id='#{marker.id}'></span>
    """
    div

  ##    ##     ##    ###    ########  ##    ## ######## ########   ######
  ##    ###   ###   ## ##   ##     ## ##   ##  ##       ##     ## ##    ##
  ##    #### ####  ##   ##  ##     ## ##  ##   ##       ##     ## ##
  ##    ## ### ## ##     ## ########  #####    ######   ########   ######
  ##    ##     ## ######### ##   ##   ##  ##   ##       ##   ##         ##
  ##    ##     ## ##     ## ##    ##  ##   ##  ##       ##    ##  ##    ##
  ##    ##     ## ##     ## ##     ## ##    ## ######## ##     ##  ######

  requestMarkerUpdate: (markers) ->
    if @frameRequested
      @dirtyMarkers = @dirtyMarkers.concat(markers)
      return
    else
      @dirtyMarkers = markers.slice()
      @frameRequested = true

    requestAnimationFrame =>
      dirtyMarkers = []
      dirtyMarkers.push(m) for m in @dirtyMarkers when m not in dirtyMarkers

      delete @frameRequested
      delete @dirtyMarkers

      return unless @colorBuffer?

      dirtyMarkers.forEach (marker) -> marker.render()

  updateMarkers: ->
    return if @editor.isDestroyed()

    markers = @colorBuffer.findValidColorMarkers({
      intersectsScreenRowRange: @editorElement.getVisibleRowRange?() ? @editor.getVisibleRowRange?()
    })

    for m in @displayedMarkers when m not in markers
      @releaseMarkerView(m)

    for m in markers when m.color?.isValid() and m not in @displayedMarkers
      @requestMarkerView(m)

    @displayedMarkers = markers

    @emitter.emit 'did-update'

  requestMarkerView: (marker) ->
    if @unusedMarkers.length
      view = @unusedMarkers.shift()
    else
      view = new ColorMarkerElement
      view.setContainer(this)
      view.onDidRelease ({marker}) =>
        @displayedMarkers.splice(@displayedMarkers.indexOf(marker), 1)
        @releaseMarkerView(marker)
      @shadowRoot.appendChild view

    view.setModel(marker)

    @hideMarkerIfInSelectionOrFold(marker, view)
    @usedMarkers.push(view)
    @viewsByMarkers.set(marker, view)
    view

  releaseMarkerView: (markerOrView) ->
    marker = markerOrView
    view = @viewsByMarkers.get(markerOrView)

    if view?
      @viewsByMarkers.delete(marker) if marker?
      @releaseMarkerElement(view)

  releaseMarkerElement: (view) ->
    @usedMarkers.splice(@usedMarkers.indexOf(view), 1)
    view.release(false) unless view.isReleased()
    @unusedMarkers.push(view)

  releaseAllMarkerViews: ->
    view.destroy() for view in @usedMarkers
    view.destroy() for view in @unusedMarkers

    @usedMarkers = []
    @unusedMarkers = []

    Array::forEach.call @shadowRoot.querySelectorAll('pigments-color-marker'), (el) -> el.parentNode.removeChild(el)

  ##     ######  ######## ##       ########  ######  ########
  ##    ##    ## ##       ##       ##       ##    ##    ##
  ##    ##       ##       ##       ##       ##          ##
  ##     ######  ######   ##       ######   ##          ##
  ##          ## ##       ##       ##       ##          ##
  ##    ##    ## ##       ##       ##       ##    ##    ##
  ##     ######  ######## ######## ########  ######     ##

  requestSelectionUpdate: ->
    return if @updateRequested or @useGutter()

    @updateRequested = true
    requestAnimationFrame =>
      @updateRequested = false
      return if @editor.getBuffer().isDestroyed()
      @updateSelections()

  updateSelections: ->
    return if @editor.isDestroyed() or @useGutter()
    for marker in @displayedMarkers
      view = @viewsByMarkers.get(marker)
      if view?
        view.classList.remove('hidden')
        view.classList.remove('in-fold')
        @hideMarkerIfInSelectionOrFold(marker, view)
      else
        console.warn "A color marker was found in the displayed markers array without an associated view", marker

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
    bufferPosition = @colorBuffer.editor.bufferPositionForScreenPosition(position)

    @colorBuffer.getColorMarkerAtBufferPosition(bufferPosition)

  screenPositionForMouseEvent: (event) ->
    pixelPosition = @pixelPositionForMouseEvent(event)

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
    {top, left} = rootElement.querySelector('.lines').getBoundingClientRect()
    top = clientY - top + scrollTarget.getScrollTop()
    left = clientX - left + scrollTarget.getScrollLeft()
    {top, left}

module.exports =
ColorBufferElement =
registerOrUpdateElement 'pigments-markers', ColorBufferElement.prototype

ColorBufferElement.registerViewProvider = (modelClass) ->
  atom.views.addViewProvider modelClass, (model) ->
    element = new ColorBufferElement
    element.setModel(model)
    element
