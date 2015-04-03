{Emitter, CompositeDisposable} = require 'atom'
ColorMarkerElement = require './color-marker-element'

class ColorBufferElement extends HTMLElement

  createdCallback: ->
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
    @updateMarkers()

  detachedCallback: ->

  onDidUpdate: (callback) ->
    @emitter.on 'did-update', callback

  getModel: -> @colorBuffer

  setModel: (@colorBuffer) ->
    {@editor} = @colorBuffer

    @colorBuffer.initialize().then =>
      @updateMarkers()
    @subscriptions.add @colorBuffer.onDidUpdateColorMarkers =>
      @updateMarkers()
    @subscriptions.add @editor.onDidChangeScrollTop =>
      @updateMarkers()

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

    @attach()

  attach: ->
    @editorElement = atom.views.getView(@editor)
    @editorElement.shadowRoot.querySelector('.lines').appendChild(this)

  requestSelectionUpdate: ->
    return if @updateRequested

    @updateRequested = true
    requestAnimationFrame =>
      @updateRequested = false
      return if @editor.getBuffer().isDestroyed()
      @updateSelections()

  updateSelections: ->
    for marker in @displayedMarkers
      view = @viewsByMarkers.get(marker)
      view.style.display = ''

      @hideMarkerIfInSelection(marker, view)

  updateMarkers: ->
    markers = @colorBuffer.findColorMarkers({
      intersectsScreenRowRange: @editor.displayBuffer.getVisibleRowRange()
    }).filter (marker) -> marker?.color?.isValid()

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
      view.onDidRelease => @releaseMarkerView(view)
      @shadowRoot.appendChild view

    view.setModel(marker)

    @hideMarkerIfInSelection(marker, view)
    @usedMarkers.push(view)
    @viewsByMarkers.set(marker, view)
    view

  releaseMarkerView: (marker) ->
    view = @viewsByMarkers.get(marker)
    if view?
      @viewsByMarkers.delete(marker)
      @usedMarkers.splice(@usedMarkers.indexOf(view), 1)
      view.release(false) unless view.isReleased()
      @unusedMarkers.push(view)

  hideMarkerIfInSelection: (marker, view) ->
    selections = @editor.getSelections()

    for selection in selections
      range = selection.getScreenRange()
      markerRange = marker.marker?.getScreenRange()

      continue unless markerRange? and range?

      if markerRange.intersectsWith(range)
        view.style.display = 'none'

module.exports = ColorBufferElement =
document.registerElement 'pigments-markers', {
  prototype: ColorBufferElement.prototype
}

ColorBufferElement.registerViewProvider = (modelClass) ->
  atom.views.addViewProvider modelClass, (model) ->
    element = new ColorBufferElement
    element.setModel(model)
    element
