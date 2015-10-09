{Emitter, CompositeDisposable} = require 'atom'
ColorMarkerElement = require './color-marker-element'

class ColorBufferElement extends HTMLElement

  createdCallback: ->
    [@editorScrollLeft, @editorScrollTop] = [0, 0]
    @emitter = new Emitter
    @subscriptions = new CompositeDisposable
    @shadowRoot = @createShadowRoot()
    @displayedMarkers = []
    @usedMarkers = []
    @unusedMarkers = []
    @viewsByMarkers = new WeakMap

    @subscriptions.add atom.config.observe 'pigments.markerType', (type) =>
      if type is 'background'
        @classList.add('above-editor-content')
      else
        @classList.remove('above-editor-content')

  attachedCallback: ->
    @attached = true
    @updateMarkers()

  detachedCallback: ->
    @attached = false

  onDidUpdate: (callback) ->
    @emitter.on 'did-update', callback

  getModel: -> @colorBuffer

  setModel: (@colorBuffer) ->
    {@editor} = @colorBuffer
    return if @editor.isDestroyed()
    @editorElement = atom.views.getView(@editor)

    @colorBuffer.initialize().then => @updateMarkers()

    @subscriptions.add @colorBuffer.onDidUpdateColorMarkers => @updateMarkers()
    @subscriptions.add @colorBuffer.onDidDestroy => @destroy()

    scrollLeftListener = (@editorScrollLeft) => @updateScroll()
    scrollTopListener = (@editorScrollTop) =>
      @updateScroll()
      @updateMarkers()

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
    @subscriptions.add @editor.displayBuffer.onDidTokenize =>
      @editorConfigChanged()

    @subscriptions.add atom.config.observe 'editor.fontSize', =>
      @editorConfigChanged()

    @subscriptions.add atom.config.observe 'editor.lineHeight', =>
      @editorConfigChanged()

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

  updateScroll: ->
    if @editorElement.hasTiledRendering
      @style.webkitTransform = "translate3d(#{-@editorScrollLeft}px, #{-@editorScrollTop}px, 0)"

  destroy: ->
    @detach()
    @subscriptions.dispose()
    @releaseAllMarkerViews()
    @colorModel = null

  getEditorRoot: -> @editorElement.shadowRoot ? @editorElement

  editorConfigChanged: ->
    return unless @parentNode?
    @usedMarkers.forEach (marker) =>
      if marker.colorMarker?
        marker.render()
      else
        console.warn "A marker view was found in the used instance pool while having a null model", marker
        @releaseMarkerElement(marker)

    @updateMarkers()

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
      view = @viewsByMarkers.get(marker)
      if view?
        view.classList.remove('hidden')
        @hideMarkerIfInSelection(marker, view)
      else
        console.warn "A color marker was found in the displayed markers array without an associated view", marker

  updateMarkers: ->
    return if @editor.isDestroyed()

    markers = @colorBuffer.findValidColorMarkers({
      intersectsScreenRowRange: @editorElement.getVisibleRowRange?() ? @editor.displayBuffer.getVisibleRowRange?()
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
      view.onDidRelease ({marker}) =>
        @displayedMarkers.splice(@displayedMarkers.indexOf(marker), 1)
        @releaseMarkerView(marker)
      @shadowRoot.appendChild view

    view.setModel(marker)

    @hideMarkerIfInSelection(marker, view)
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

  hideMarkerIfInSelection: (marker, view) ->
    selections = @editor.getSelections()

    for selection in selections
      range = selection.getScreenRange()
      markerRange = marker.marker?.getScreenRange()

      continue unless markerRange? and range?

      view.classList.add('hidden') if markerRange.intersectsWith(range)

  colorMarkerForMouseEvent: (event) ->
    position = @screenPositionForMouseEvent(event)
    bufferPosition = @colorBuffer.displayBuffer.bufferPositionForScreenPosition(position)

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

    rootElement = @editorElement.shadowRoot ? @editorElement
    {top, left} = rootElement.querySelector('.lines').getBoundingClientRect()
    top = clientY - top + scrollTarget.getScrollTop()
    left = clientX - left + scrollTarget.getScrollLeft()
    {top, left}

module.exports = ColorBufferElement =
document.registerElement 'pigments-markers', {
  prototype: ColorBufferElement.prototype
}

ColorBufferElement.registerViewProvider = (modelClass) ->
  atom.views.addViewProvider modelClass, (model) ->
    element = new ColorBufferElement
    element.setModel(model)
    element
