Color = require '../lib/color'
ColorMarker = require '../lib/color-marker'
ColorMarkerElement = require '../lib/color-marker-element'
{TextEditor} = require 'atom'

describe 'ColorMarkerElement', ->
  [editor, marker, colorMarker, colorMarkerElement] = []

  beforeEach ->
    editor = new TextEditor({})
    editor.setText("""
    body {
      color: red;
      bar: foo;
      foo: bar;
    }
    """)
    marker = editor.markBufferRange([[1,9],[4,1]], {
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
    [regions] = []
    beforeEach ->
      ColorMarkerElement.setMarkerType('background')

      colorMarkerElement = new ColorMarkerElement
      colorMarkerElement.setModel(colorMarker)

      regions = colorMarkerElement.querySelectorAll('.region.background')

    it 'creates a region div for the color', ->
      expect(regions.length).toEqual(4)

    it 'fills the region with the covered text', ->
      expect(regions[0].textContent).toEqual('red;')
      expect(regions[1].textContent).toEqual('  bar: foo;')
      expect(regions[2].textContent).toEqual('  foo: bar;')
      expect(regions[3].textContent).toEqual('}')

    it 'sets the background of the region with the color css value', ->
      for region in regions
        expect(region.style.backgroundColor).toEqual('rgb(255, 0, 0)')

    describe 'when the marker is modified', ->
      beforeEach ->
        spyOn(colorMarkerElement.renderer, 'render').andCallThrough()
        editor.moveToTop()
        editor.insertText('\n\n')

      it 'renders again the marker content', ->
        expect(colorMarkerElement.renderer.render).toHaveBeenCalled()
        expect(colorMarkerElement.querySelectorAll('.region').length).toEqual(4)

    describe 'when released', ->
      it 'removes all the previously rendered content', ->
        colorMarkerElement.release()
        expect(colorMarkerElement.children.length).toEqual(0)

  describe 'when the render mode is set to outline', ->
    [regions] = []
    beforeEach ->
      ColorMarkerElement.setMarkerType('outline')

      colorMarkerElement = new ColorMarkerElement
      colorMarkerElement.setModel(colorMarker)

      regions = colorMarkerElement.querySelectorAll('.region.outline')

    it 'creates a region div for the color', ->
      expect(regions.length).toEqual(4)

    it 'fills the region with the covered text', ->
      expect(regions[0].textContent).toEqual('')
      expect(regions[1].textContent).toEqual('')
      expect(regions[2].textContent).toEqual('')
      expect(regions[3].textContent).toEqual('')

    it 'sets the drop shadow color of the region with the color css value', ->
      for region in regions
        expect(colorMarkerElement.style.webkitFilter).toEqual('drop-shadow(rgb(255, 0, 0) 0px 0px 1px) drop-shadow(rgb(255, 0, 0) 0px 0px 1px) drop-shadow(rgb(255, 0, 0) 0px 0px 1px) drop-shadow(rgb(255, 0, 0) 0px 0px 1px)')

    describe 'when the marker is modified', ->
      beforeEach ->
        spyOn(colorMarkerElement.renderer, 'render').andCallThrough()
        editor.moveToTop()
        editor.insertText('\n\n')

      it 'renders again the marker content', ->
        expect(colorMarkerElement.renderer.render).toHaveBeenCalled()
        expect(colorMarkerElement.querySelectorAll('.region').length).toEqual(4)

    describe 'when released', ->
      it 'removes all the previously rendered content', ->
        colorMarkerElement.release()
        expect(colorMarkerElement.children.length).toEqual(0)

  describe 'when the render mode is set to underline', ->
    [regions] = []
    beforeEach ->
      ColorMarkerElement.setMarkerType('underline')

      colorMarkerElement = new ColorMarkerElement
      colorMarkerElement.setModel(colorMarker)

      regions = colorMarkerElement.querySelectorAll('.region.underline')

    it 'creates a region div for the color', ->
      expect(regions.length).toEqual(4)

    it 'fills the region with the covered text', ->
      expect(regions[0].textContent).toEqual('')
      expect(regions[1].textContent).toEqual('')
      expect(regions[2].textContent).toEqual('')
      expect(regions[3].textContent).toEqual('')

    describe 'when the marker is modified', ->
      beforeEach ->
        spyOn(colorMarkerElement.renderer, 'render').andCallThrough()
        editor.moveToTop()
        editor.insertText('\n\n')

      it 'renders again the marker content', ->
        expect(colorMarkerElement.renderer.render).toHaveBeenCalled()
        expect(colorMarkerElement.querySelectorAll('.region').length).toEqual(4)

    describe 'when released', ->
      it 'removes all the previously rendered content', ->
        colorMarkerElement.release()
        expect(colorMarkerElement.children.length).toEqual(0)
