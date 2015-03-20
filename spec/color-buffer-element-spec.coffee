path = require 'path'
ColorBufferElement = require '../lib/color-buffer-element'
ColorMarkerElement = require '../lib/color-marker-element'

describe 'ColorBufferElement', ->
  [editor, editorElement, colorBuffer, pigments, project, colorBufferElement, jasmineContent] = []

  editBuffer = (text, options={}) ->
    if options.start?
      if options.end?
        range = [options.start, options.end]
      else
        range = [options.start, options.start]

      editor.setSelectedBufferRange(range)

    editor.insertText(text)
    editor.getBuffer().emitter.emit('did-stop-changing') unless options.noEvent

  jsonFixture = (fixture, data) ->
    jsonPath = path.resolve(__dirname, 'fixtures', fixture)
    json = fs.readFileSync(jsonPath).toString()
    json = json.replace /#\{(\w+)\}/g, (m,w) -> data[w]

    JSON.parse(json)


  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    jasmineContent = document.body.querySelector('#jasmine-content')

    jasmineContent.appendChild(workspaceElement)

    atom.config.set 'pigments.sourceNames', [
      '*.styl'
      '*.less'
    ]

    waitsForPromise ->
      atom.workspace.open('four-variables.styl').then (o) ->
        editor = o
        editorElement = atom.views.getView(editor)

    waitsForPromise -> atom.packages.activatePackage('pigments').then (pkg) ->
      pigments = pkg.mainModule
      project = pigments.getProject()

  describe 'when an editor is opened', ->
    beforeEach ->
      colorBuffer = project.colorBufferForEditor(editor)
      colorBufferElement = atom.views.getView(colorBuffer)

    it 'is associated to the ColorBuffer model', ->
      expect(colorBufferElement).toBeDefined()
      expect(colorBufferElement.getModel()).toBe(colorBuffer)

    it 'attaches itself in the target text editor element', ->
      expect(colorBufferElement.parentNode).toExist()
      expect(editorElement.shadowRoot.querySelector('.lines pigments-markers')).toExist()

    describe 'when the color buffer is initialized', ->
      beforeEach ->
        waitsForPromise -> colorBuffer.initialize()

      it 'creates markers views for every visible buffer markers', ->
        markersElements = colorBufferElement.shadowRoot.querySelectorAll('pigments-color-marker')

        expect(markersElements.length).toEqual(3)

        for marker in markersElements
          expect(marker.getModel()).toBeDefined()

      describe 'when the project variables are initialized', ->
        it 'creates markers for the new valid colors', ->
          waitsForPromise -> colorBuffer.variablesAvailable()
          runs ->
            expect(colorBufferElement.shadowRoot.querySelectorAll('pigments-color-marker').length).toEqual(4)

      describe 'when some markers are destroyed', ->
        [spy] = []
        beforeEach ->
          for el in colorBufferElement.usedMarkers
            spyOn(el, 'release').andCallThrough()

          spy = jasmine.createSpy('did-update')
          colorBufferElement.onDidUpdate(spy)
          editBuffer '', start: [4,0], end: [8,0]
          waitsFor -> spy.callCount > 0

        it 'releases the unused markers', ->
          expect(colorBufferElement.shadowRoot.querySelectorAll('pigments-color-marker').length).toEqual(3)
          expect(colorBufferElement.usedMarkers.length).toEqual(2)
          expect(colorBufferElement.unusedMarkers.length).toEqual(1)

          for marker in colorBufferElement.unusedMarkers
            expect(marker.release).toHaveBeenCalled()

        describe 'and then some new marker are created', ->
          beforeEach ->
            spy = jasmine.createSpy('did-update')
            colorBufferElement.onDidUpdate(spy)

            editor.moveToBottom()
            editBuffer 'foo = #123456'
            waitsFor -> spy.callCount > 0

          it 'reuses the previously released marker element', ->
            expect(colorBufferElement.shadowRoot.querySelectorAll('pigments-color-marker').length).toEqual(3)
            expect(colorBufferElement.usedMarkers.length).toEqual(3)
            expect(colorBufferElement.unusedMarkers.length).toEqual(0)
