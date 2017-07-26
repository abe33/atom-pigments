path = require 'path'
require './helpers/spec-helper'
{mousedown} = require './helpers/events'

ColorBufferElement = require '../lib/color-buffer-element'

sleep = (duration) ->
  t = new Date()
  waitsFor -> new Date() - t > duration

describe 'ColorBufferElement', ->
  [editor, editorElement, colorBuffer, pigments, project, colorBufferElement, jasmineContent] = []

  isVisible = (decoration) ->
    not /-in-selection/.test decoration.properties.class

  editBuffer = (text, options={}) ->
    if options.start?
      if options.end?
        range = [options.start, options.end]
      else
        range = [options.start, options.start]

      editor.setSelectedBufferRange(range)

    editor.insertText(text)
    advanceClock(500) unless options.noEvent

  jsonFixture = (fixture, data) ->
    jsonPath = path.resolve(__dirname, 'fixtures', fixture)
    json = fs.readFileSync(jsonPath).toString()
    json = json.replace /#\{(\w+)\}/g, (m,w) -> data[w]

    JSON.parse(json)

  getEditorDecorations = (type) ->
    editor.getDecorations()
    .filter((d) -> d.properties.class.startsWith 'pigments-native-background')

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    jasmineContent = document.body.querySelector('#jasmine-content')

    jasmineContent.appendChild(workspaceElement)

    atom.config.set 'editor.softWrap', true
    atom.config.set 'editor.softWrapAtPreferredLineLength', true
    atom.config.set 'editor.preferredLineLength', 40

    atom.config.set 'pigments.delayBeforeScan', 0
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

  afterEach ->
    colorBuffer?.destroy()

  describe 'when an editor is opened', ->
    beforeEach ->
      colorBuffer = project.colorBufferForEditor(editor)
      colorBufferElement = atom.views.getView(colorBuffer)
      colorBufferElement.attach()

    it 'is associated to the ColorBuffer model', ->
      expect(colorBufferElement).toBeDefined()
      expect(colorBufferElement.getModel()).toBe(colorBuffer)

    it 'attaches itself in the target text editor element', ->
      expect(colorBufferElement.parentNode).toExist()
      expect(editorElement.querySelector('.lines pigments-markers')).toExist()

    describe 'when the color buffer is initialized', ->
      beforeEach ->
        waitsForPromise -> colorBuffer.initialize()

      it 'creates markers views for every visible buffer marker', ->
        expect(getEditorDecorations('native-background').length).toEqual(3)

      describe 'when the project variables are initialized', ->
        it 'creates markers for the new valid colors', ->
          waitsForPromise -> colorBuffer.variablesAvailable()
          runs ->
            expect(getEditorDecorations('native-background').length).toEqual(4)

      describe 'when a selection intersects a marker range', ->
        beforeEach ->
          spyOn(colorBufferElement, 'updateSelections').andCallThrough()

        describe 'after the markers views was created', ->
          beforeEach ->
            waitsForPromise -> colorBuffer.variablesAvailable()
            runs -> editor.setSelectedBufferRange [[2,12],[2, 14]]
            waitsFor -> colorBufferElement.updateSelections.callCount > 0

          it 'hides the intersected marker', ->
            decorations = getEditorDecorations('native-background')

            expect(isVisible(decorations[0])).toBeTruthy()
            expect(isVisible(decorations[1])).toBeTruthy()
            expect(isVisible(decorations[2])).toBeTruthy()
            expect(isVisible(decorations[3])).toBeFalsy()

        describe 'before all the markers views was created', ->
          beforeEach ->
            runs -> editor.setSelectedBufferRange [[0,0],[2, 14]]
            waitsFor -> colorBufferElement.updateSelections.callCount > 0

          it 'hides the existing markers', ->
            decorations = getEditorDecorations('native-background')

            expect(isVisible(decorations[0])).toBeFalsy()
            expect(isVisible(decorations[1])).toBeTruthy()
            expect(isVisible(decorations[2])).toBeTruthy()

          describe 'and the markers are updated', ->
            beforeEach ->
              waitsForPromise 'colors available', ->
                colorBuffer.variablesAvailable()
              waitsFor 'last marker visible', ->
                decorations = getEditorDecorations('native-background')
                isVisible(decorations[3])

            it 'hides the created markers', ->
              decorations = getEditorDecorations('native-background')
              expect(isVisible(decorations[0])).toBeFalsy()
              expect(isVisible(decorations[1])).toBeTruthy()
              expect(isVisible(decorations[2])).toBeTruthy()
              expect(isVisible(decorations[3])).toBeTruthy()

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
          expect(getEditorDecorations('native-background').length).toEqual(2)

      describe 'when the current pane is splitted to the right', ->
        beforeEach ->
          version = parseFloat(atom.getVersion().split('.').slice(1,2).join('.'))
          if version > 5
            atom.commands.dispatch(editorElement, 'pane:split-right-and-copy-active-item')
          else
            atom.commands.dispatch(editorElement, 'pane:split-right')

          waitsFor 'text editor', ->
            editor = atom.workspace.getTextEditors()[1]

          waitsFor 'color buffer element', ->
            colorBufferElement = atom.views.getView(project.colorBufferForEditor(editor))
          waitsFor 'color buffer element markers', ->
            getEditorDecorations('native-background').length

        it 'should keep all the buffer elements attached', ->
          editors = atom.workspace.getTextEditors()

          editors.forEach (editor) ->
            editorElement = atom.views.getView(editor)
            colorBufferElement = editorElement.querySelector('pigments-markers')
            expect(colorBufferElement).toExist()

            expect(getEditorDecorations('native-background').length).toEqual(4)

      describe 'when the marker type is set to gutter', ->
        [gutter] = []

        beforeEach ->
          waitsForPromise -> colorBuffer.initialize()
          runs ->
            atom.config.set 'pigments.markerType', 'gutter'
            gutter = editorElement.querySelector('[gutter-name="pigments-gutter"]')

        it 'removes the markers', ->
          expect(colorBufferElement.querySelectorAll('pigments-color-marker').length).toEqual(0)

        it 'adds a custom gutter to the text editor', ->
          expect(gutter).toExist()

        it 'sets the size of the gutter based on the number of markers in the same row', ->
          expect(gutter.style.minWidth).toEqual('14px')

        it 'adds a gutter decoration for each color marker', ->
          decorations = editor.getDecorations().filter (d) ->
            d.properties.type is 'gutter'
          expect(decorations.length).toEqual(3)

        describe 'when the variables become available', ->
          beforeEach ->
            waitsForPromise -> colorBuffer.variablesAvailable()

          it 'creates decorations for the new valid colors', ->
            decorations = editor.getDecorations().filter (d) ->
              d.properties.type is 'gutter'
            expect(decorations.length).toEqual(4)

          describe 'when many markers are added on the same line', ->
            beforeEach ->
              updateSpy = jasmine.createSpy('did-update')
              colorBufferElement.onDidUpdate(updateSpy)

              editor.moveToBottom()
              editBuffer '\nlist = #123456, #987654, #abcdef\n'
              waitsFor -> updateSpy.callCount > 0

            it 'adds the new decorations to the gutter', ->
              decorations = editor.getDecorations().filter (d) ->
                d.properties.type is 'gutter'

              expect(decorations.length).toEqual(7)

            it 'sets the size of the gutter based on the number of markers in the same row', ->
              expect(gutter.style.minWidth).toEqual('42px')

            describe 'clicking on a gutter decoration', ->
              beforeEach ->
                project.colorPickerAPI =
                  open: jasmine.createSpy('color-picker.open')

                decoration = editorElement.querySelector('.pigments-gutter-marker span')
                mousedown(decoration)

              it 'selects the text in the editor', ->
                expect(editor.getSelectedScreenRange()).toEqual([[0,13],[0,17]])

              it 'opens the color picker', ->
                expect(project.colorPickerAPI.open).toHaveBeenCalled()

        describe 'when the marker is changed again', ->
          beforeEach ->
            atom.config.set 'pigments.markerType', 'native-background'

          it 'removes the gutter', ->
            expect(editorElement.querySelector('[gutter-name="pigments-gutter"]')).not.toExist()

          it 'recreates the markers', ->
            expect(getEditorDecorations('native-background').length).toEqual(3)

        describe 'when a new buffer is opened', ->
          beforeEach ->
            waitsForPromise ->
              atom.workspace.open('project/styles/variables.styl').then (e) ->
                editor = e
                editorElement = atom.views.getView(editor)
                colorBuffer = project.colorBufferForEditor(editor)
                colorBufferElement = atom.views.getView(colorBuffer)

            waitsForPromise -> colorBuffer.initialize()
            waitsForPromise -> colorBuffer.variablesAvailable()

            runs ->
              gutter = editorElement.querySelector('[gutter-name="pigments-gutter"]')

          it 'creates the decorations in the new buffer gutter', ->
            decorations = editor.getDecorations().filter (d) ->
              d.properties.type is 'gutter'

            expect(decorations.length).toEqual(10)

    describe 'when the editor is moved to another pane', ->
      [pane, newPane] = []
      beforeEach ->
        pane = atom.workspace.getActivePane()
        newPane = pane.splitDown(copyActiveItem: false)
        colorBuffer = project.colorBufferForEditor(editor)
        colorBufferElement = atom.views.getView(colorBuffer)

        pane.moveItemToPane(editor, newPane, 0)

        waitsFor ->
          getEditorDecorations('native-background').length

      it 'moves the editor with the buffer to the new pane', ->
        expect(getEditorDecorations('native-background').length).toEqual(3)

    describe 'when pigments.supportedFiletypes settings is defined', ->
      loadBuffer = (filePath) ->
        waitsForPromise ->
          atom.workspace.open(filePath).then (o) ->
            editor = o
            editorElement = atom.views.getView(editor)
            colorBuffer = project.colorBufferForEditor(editor)
            colorBufferElement = atom.views.getView(colorBuffer)
            colorBufferElement.attach()

        waitsForPromise -> colorBuffer.initialize()
        waitsForPromise -> colorBuffer.variablesAvailable()

      beforeEach ->
        waitsForPromise ->
          atom.packages.activatePackage('language-coffee-script')
        waitsForPromise ->
          atom.packages.activatePackage('language-less')

      describe 'with the default wildcard', ->
        beforeEach ->
          atom.config.set 'pigments.supportedFiletypes', ['*']

        it 'supports every filetype', ->
          loadBuffer('scope-filter.coffee')
          runs ->
            expect(getEditorDecorations('native-background').length).toEqual(2)

          loadBuffer('project/vendor/css/variables.less')
          runs ->
            expect(getEditorDecorations('native-background').length).toEqual(20)

      describe 'with a filetype', ->
        beforeEach ->
          atom.config.set 'pigments.supportedFiletypes', ['coffee']

        it 'supports the specified file type', ->
          loadBuffer('scope-filter.coffee')
          runs ->
            expect(getEditorDecorations('native-background').length).toEqual(2)

          loadBuffer('project/vendor/css/variables.less')
          runs ->
            expect(getEditorDecorations('native-background').length).toEqual(0)

      describe 'with many filetypes', ->
        beforeEach ->
          atom.config.set 'pigments.supportedFiletypes', ['coffee']
          project.setSupportedFiletypes(['less'])

        it 'supports the specified file types', ->
          loadBuffer('scope-filter.coffee')
          runs ->
            expect(getEditorDecorations('native-background').length).toEqual(2)

          loadBuffer('project/vendor/css/variables.less')
          runs ->
            expect(getEditorDecorations('native-background').length).toEqual(20)

          loadBuffer('four-variables.styl')
          runs ->
            expect(getEditorDecorations('native-background').length).toEqual(0)

        describe 'with global file types ignored', ->
          beforeEach ->
            atom.config.set 'pigments.supportedFiletypes', ['coffee']
            project.setIgnoreGlobalSupportedFiletypes(true)
            project.setSupportedFiletypes(['less'])

          it 'supports the specified file types', ->
            loadBuffer('scope-filter.coffee')
            runs ->
              expect(getEditorDecorations('native-background').length).toEqual(0)

            loadBuffer('project/vendor/css/variables.less')
            runs ->
              expect(getEditorDecorations('native-background').length).toEqual(20)

            loadBuffer('four-variables.styl')
            runs ->
              expect(getEditorDecorations('native-background').length).toEqual(0)

    describe 'when pigments.ignoredScopes settings is defined', ->
      beforeEach ->
        waitsForPromise ->
          atom.packages.activatePackage('language-coffee-script')

        waitsForPromise ->
          atom.workspace.open('scope-filter.coffee').then (o) ->
            editor = o
            editorElement = atom.views.getView(editor)
            colorBuffer = project.colorBufferForEditor(editor)
            colorBufferElement = atom.views.getView(colorBuffer)
            colorBufferElement.attach()

        waitsForPromise -> colorBuffer.initialize()

      describe 'with one filter', ->
        beforeEach ->
          atom.config.set('pigments.ignoredScopes', ['\\.comment'])

        it 'ignores the colors that matches the defined scopes', ->
          expect(getEditorDecorations('native-background').length).toEqual(1)

      describe 'with two filters', ->
        beforeEach ->
          atom.config.set('pigments.ignoredScopes', ['\\.string', '\\.comment'])

        it 'ignores the colors that matches the defined scopes', ->
          expect(getEditorDecorations('native-background').length).toEqual(0)

      describe 'with an invalid filter', ->
        beforeEach ->
          atom.config.set('pigments.ignoredScopes', ['\\'])

        it 'ignores the filter', ->
          expect(getEditorDecorations('native-background').length).toEqual(2)

      describe 'when the project ignoredScopes is defined', ->
        beforeEach ->
          atom.config.set('pigments.ignoredScopes', ['\\.string'])
          project.setIgnoredScopes(['\\.comment'])

        it 'ignores the colors that matches the defined scopes', ->
          expect(getEditorDecorations('native-background').length).toEqual(0)
