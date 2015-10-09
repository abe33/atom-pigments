path = require 'path'
Color = require '../lib/color'
ColorMarker = require '../lib/color-marker'
ColorMarkerElement = require '../lib/color-marker-element'
{TextEditor} = require 'atom'

stylesheetPath = path.resolve __dirname, '..', 'styles', 'pigments.less'
stylesheet = atom.themes.loadStylesheet(stylesheetPath)

describe 'ColorMarkerElement', ->
  [editor, marker, colorMarker, colorMarkerElement, jasmineContent] = []

  beforeEach ->
    jasmineContent = document.body.querySelector('#jasmine-content')

    styleNode = document.createElement('style')
    styleNode.textContent = """
      #{stylesheet}
    """

    jasmineContent.appendChild(styleNode)

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

    colorMarker = new ColorMarker({
      marker
      color
      text
      colorBuffer: {
        editor
        ignoredScopes: []
      }
    })

  it 'releases itself when the marker is destroyed', ->
    colorMarkerElement = new ColorMarkerElement
    colorMarkerElement.setModel(colorMarker)

    eventSpy = jasmine.createSpy('did-release')
    colorMarkerElement.onDidRelease(eventSpy)
    spyOn(colorMarkerElement, 'release').andCallThrough()

    marker.destroy()

    expect(colorMarkerElement.release).toHaveBeenCalled()
    expect(eventSpy).toHaveBeenCalled()

  ##    ########     ###     ######  ##    ##
  ##    ##     ##   ## ##   ##    ## ##   ##
  ##    ##     ##  ##   ##  ##       ##  ##
  ##    ########  ##     ## ##       #####
  ##    ##     ## ######### ##       ##  ##
  ##    ##     ## ##     ## ##    ## ##   ##
  ##    ########  ##     ##  ######  ##    ##

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

  ##     #######  ##     ## ######## ##       #### ##    ## ########
  ##    ##     ## ##     ##    ##    ##        ##  ###   ## ##
  ##    ##     ## ##     ##    ##    ##        ##  ####  ## ##
  ##    ##     ## ##     ##    ##    ##        ##  ## ## ## ######
  ##    ##     ## ##     ##    ##    ##        ##  ##  #### ##
  ##    ##     ## ##     ##    ##    ##        ##  ##   ### ##
  ##     #######   #######     ##    ######## #### ##    ## ########

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
        expect(region.style.borderColor).toEqual('rgb(255, 0, 0)')

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

  ##    ##     ## ##    ## ########  ######## ########
  ##    ##     ## ###   ## ##     ## ##       ##     ##
  ##    ##     ## ####  ## ##     ## ##       ##     ##
  ##    ##     ## ## ## ## ##     ## ######   ########
  ##    ##     ## ##  #### ##     ## ##       ##   ##
  ##    ##     ## ##   ### ##     ## ##       ##    ##
  ##     #######  ##    ## ########  ######## ##     ##

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

  ##    ########   #######  ########
  ##    ##     ## ##     ##    ##
  ##    ##     ## ##     ##    ##
  ##    ##     ## ##     ##    ##
  ##    ##     ## ##     ##    ##
  ##    ##     ## ##     ##    ##
  ##    ########   #######     ##

  describe 'when the render mode is set to dot', ->
    [regions, markers, markersElements] = []

    createMarker = (range, color, text) ->
      marker = editor.markBufferRange(range, {
        type: 'pigments-color'
        invalidate: 'touch'
      })
      color = new Color(color)
      text = text

      colorMarker = new ColorMarker({
        marker
        color
        text
        colorBuffer: {
          editor
          ignoredScopes: []
        }
      })

    beforeEach ->
      editor = new TextEditor({})
      editor.setText("""
      body {
        background: red, green, blue;
      }
      """)

      editorElement = atom.views.getView(editor)
      jasmineContent.appendChild(editorElement)

      markers = [
        createMarker [[1,13],[1,16]], '#ff0000', 'red'
        createMarker [[1,18],[1,23]], '#00ff00', 'green'
        createMarker [[1,25],[1,29]], '#0000ff', 'blue'
      ]

      ColorMarkerElement.setMarkerType('dot')

      markersElements = markers.map (colorMarker) ->
        colorMarkerElement = new ColorMarkerElement
        colorMarkerElement.setModel(colorMarker)

        jasmineContent.appendChild(colorMarkerElement)
        colorMarkerElement

    it 'adds the dot class on the marker', ->
      for markersElement in markersElements
        expect(markersElement.classList.contains('dot')).toBeTruthy()

  ##     ######   #######  ##     ##    ###    ########  ########
  ##    ##    ## ##     ## ##     ##   ## ##   ##     ## ##
  ##    ##       ##     ## ##     ##  ##   ##  ##     ## ##
  ##     ######  ##     ## ##     ## ##     ## ########  ######
  ##          ## ##  ## ## ##     ## ######### ##   ##   ##
  ##    ##    ## ##    ##  ##     ## ##     ## ##    ##  ##
  ##     ######   ##### ##  #######  ##     ## ##     ## ########

  describe 'when the render mode is set to dot', ->
    [regions, markers, markersElements] = []

    createMarker = (range, color, text) ->
      marker = editor.markBufferRange(range, {
        type: 'pigments-color'
        invalidate: 'touch'
      })
      color = new Color(color)
      text = text

      colorMarker = new ColorMarker({
        marker
        color
        text
        colorBuffer: {
          editor
          ignoredScopes: []
        }
      })

    beforeEach ->
      editor = new TextEditor({})
      editor.setText("""
      body {
        background: red, green, blue;
      }
      """)

      editorElement = atom.views.getView(editor)
      jasmineContent.appendChild(editorElement)

      markers = [
        createMarker [[1,13],[1,16]], '#ff0000', 'red'
        createMarker [[1,18],[1,23]], '#00ff00', 'green'
        createMarker [[1,25],[1,29]], '#0000ff', 'blue'
      ]

      ColorMarkerElement.setMarkerType('square-dot')

      markersElements = markers.map (colorMarker) ->
        colorMarkerElement = new ColorMarkerElement
        colorMarkerElement.setModel(colorMarker)

        jasmineContent.appendChild(colorMarkerElement)
        colorMarkerElement

    it 'adds the dot class on the marker', ->
      for markersElement in markersElements
        expect(markersElement.classList.contains('dot')).toBeTruthy()
        expect(markersElement.classList.contains('square')).toBeTruthy()
