Color = require '../lib/color'
ColorMarker = require '../lib/color-marker'
ColorMarkerElement = require '../lib/color-marker-element'
{TextEditor} = require 'atom'

describe 'ColorMarkerElement', ->
  [editor, marker, colorMarker, colorMarkerElement] = []

  beforeEach ->

    editor = new TextEditor(text: """
    body {
      color: red
    }
    """)
    marker = editor.markBufferRange([[1,9],[1,12]], type: 'pigments-color', invalidate: 'touch')
    color = new Color('#ff0000')
    text = 'red'

    colorMarker = new ColorMarker({marker, color, text})

  it 'releases itself when the marker is destroyed', ->
    colorMarkerElement = new ColorMarkerElement
    colorMarkerElement.setModel(colorMarker)

    eventSpy = jasmine.createSpy('did-release')
    colorMarkerElement.onDidRelease(eventSpy)
    spyOn(colorMarkerElement, 'release').andCallThrough()

    marker.destroy()

    expect(colorMarkerElement.release).toHaveBeenCalled()
    expect(eventSpy).toHaveBeenCalled()

  describe 'when the render mode is set to background', ->
    beforeEach ->
      ColorMarkerElement.setMarkerType('background')

      colorMarkerElement = new ColorMarkerElement
      colorMarkerElement.setModel(colorMarker)

    it 'creates a region div for the color', ->
      expect(colorMarkerElement.querySelectorAll('.region').length).toEqual(1)
