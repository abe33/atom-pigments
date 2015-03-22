Color = require '../lib/color'
ColorMarker = require '../lib/color-marker'
ColorMarkerElement = require '../lib/color-marker-element'
{TextEditor} = require 'atom'

fdescribe 'ColorMarkerElement', ->
  [editor, marker, colorMarker, colorMarkerElement] = []

  beforeEach ->
    editor = new TextEditor({})
    editor.setText("""
    body {
      color: red
    }
    """)
    marker = editor.markBufferRange([[1,9],[2,1]], {
      type: 'pigments-color'
      invalidate: 'touch'
    })
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
      expect(colorMarkerElement.querySelectorAll('.region.background').length).toEqual(2)

    it 'fills the region with the covered text', ->
      expect(colorMarkerElement.querySelector('.region').textContent).toEqual('red')
      expect(colorMarkerElement.querySelector('.region:last-child').textContent).toEqual('}')

    it 'sets the background of the region with the color css value', ->
      expect(colorMarkerElement.querySelector('.region').style.backgroundColor).toEqual('rgb(255, 0, 0)')
      expect(colorMarkerElement.querySelector('.region:last-child').style.backgroundColor).toEqual('rgb(255, 0, 0)')
