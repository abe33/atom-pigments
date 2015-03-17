ColorBuffer = require '../lib/color-buffer'

describe 'ColorBuffer', ->
  [editor, colorBuffer, pigments, project] = []

  editBuffer = (text, options={}) ->

    if options.start?
      if options.end?
        range = [options.start, options.end]
      else
        range = [options.start, options.start]

      editor.setSelectedBufferRange(range)

    editor.insertText(text)
    editor.getBuffer().emitter.emit('did-stop-changing') unless options.noEvent

  beforeEach ->
    atom.config.set 'pigments.sourceNames', [
      '*.styl'
      '*.less'
    ]

    waitsForPromise ->
      atom.workspace.open('four-variables.styl').then (o) -> editor = o

    waitsForPromise -> atom.packages.activatePackage('pigments').then (pkg) ->
      pigments = pkg.mainModule
      project = pigments.getProject()

  it 'creates a color buffer for each editor in the workspace', ->
    expect(project.colorBuffersByEditorId[editor.id]).toBeDefined()

  describe 'when created without a previous state', ->
    beforeEach ->
      colorBuffer = project.colorBufferForEditor(editor)
      waitsForPromise -> colorBuffer.initialize()

    it 'scans the buffer for colors without waiting for the project variables', ->
      expect(colorBuffer.getColorMarkers().length).toEqual(4)
      expect(colorBuffer.getValidColorMarkers().length).toEqual(3)

    it 'creates the corresponding markers in the text editor', ->
      expect(editor.findMarkers(type: 'pigments-color').length).toEqual(4)

    describe 'when the project variables becomes available', ->
      [updateSpy] = []
      beforeEach ->
        updateSpy = jasmine.createSpy('did-update-color-markers')
        colorBuffer.onDidUpdateColorMarkers(updateSpy)
        waitsForPromise -> colorBuffer.variablesAvailable()

      it 'replaces the invalid markers that are now valid', ->
        expect(colorBuffer.getValidColorMarkers().length).toEqual(4)
        expect(updateSpy.argsForCall[0][0].created.length).toEqual(1)
        expect(updateSpy.argsForCall[0][0].destroyed.length).toEqual(1)

      it 'destroys the text editor markers', ->
        expect(editor.findMarkers(type: 'pigments-color').length).toEqual(4)

      it 'creates markers for variables in the buffer', ->
        expect(colorBuffer.getVariableMarkers().length).toEqual(4)
        expect(editor.findMarkers(type: 'pigments-variable').length).toEqual(4)

      describe 'when a variable marker is edited', ->
        [colorsUpdateSpy] = []
        beforeEach ->
          updateSpy = jasmine.createSpy('did-update-variable-markers')
          colorsUpdateSpy = jasmine.createSpy('did-update-color-markers')
          colorBuffer.onDidUpdateVariableMarkers(updateSpy)
          colorBuffer.onDidUpdateColorMarkers(colorsUpdateSpy)
          editBuffer '#336699', start: [0,13], end: [0,17]
          waitsFor -> updateSpy.callCount > 0

        it 'updates the modified variable marker', ->
          expect(colorBuffer.getVariableMarkerByName('base-color').variable.value).toEqual('#336699')

        it 'has the same number of variables than before', ->
          expect(colorBuffer.getVariableMarkers().length).toEqual(4)
          expect(editor.findMarkers(type: 'pigments-variable').length).toEqual(4)

        it 'updates the modified colors', ->
          waitsFor -> colorsUpdateSpy.callCount > 0
          runs ->
            expect(colorsUpdateSpy.argsForCall[0][0].destroyed.length).toEqual(2)
            expect(colorsUpdateSpy.argsForCall[0][0].created.length).toEqual(2)

      describe 'when a new variable is added', ->
        [colorsUpdateSpy] = []

        beforeEach ->
          waitsForPromise -> colorBuffer.variablesAvailable()

          runs ->
            updateSpy = jasmine.createSpy('did-update-variable-markers')
            colorBuffer.onDidUpdateColorMarkers(updateSpy)
            editor.moveToBottom()
            editBuffer '\nfoo = base-color'
            waitsFor -> updateSpy.callCount > 0

        it 'adds a marker for the new variable', ->
          expect(colorBuffer.getVariableMarkers().length).toEqual(5)
          expect(colorBuffer.getVariableMarkerByName('foo').variable.value).toEqual('base-color')
          expect(editor.findMarkers(type: 'pigments-variable').length).toEqual(5)

        it 'dispatches the new marker in a did-update-variable-markers event', ->
          expect(updateSpy.argsForCall[0][0].destroyed.length).toEqual(0)
          expect(updateSpy.argsForCall[0][0].created.length).toEqual(1)

      describe 'when a variable marker is removed', ->
        [colorsUpdateSpy] = []
        beforeEach ->
          updateSpy = jasmine.createSpy('did-update-variable-markers')
          colorsUpdateSpy = jasmine.createSpy('did-update-color-markers')
          colorBuffer.onDidUpdateVariableMarkers(updateSpy)
          colorBuffer.onDidUpdateColorMarkers(colorsUpdateSpy)
          editBuffer '', start: [0,0], end: [0,17]
          waitsFor -> updateSpy.callCount > 0

        it 'updates the modified variable marker', ->
          expect(colorBuffer.getVariableMarkerByName('base-color')).toBeUndefined()

        it 'dispatches the new marker in a did-update-variable-markers event', ->
          expect(updateSpy.argsForCall[0][0].destroyed.length).toEqual(1)
          expect(updateSpy.argsForCall[0][0].created.length).toEqual(0)

        it 'invalidates colors that were relying on the deleted variables', ->
          waitsFor -> colorsUpdateSpy.callCount > 0
          runs ->
            expect(colorBuffer.getColorMarkers().length).toEqual(3)
            expect(colorBuffer.getValidColorMarkers().length).toEqual(2)

    describe 'with a buffer with only colors', ->
      beforeEach ->
        waitsForPromise ->
          atom.workspace.open('buttons.styl').then (o) -> editor = o

        runs ->
          colorBuffer = project.colorBufferForEditor(editor)

      it 'creates the color markers for the variables used in the buffer', ->
        waitsForPromise -> colorBuffer.initialize()
        runs -> expect(colorBuffer.getColorMarkers().length).toEqual(0)

      it 'creates the color markers for the variables used in the buffer', ->
        waitsForPromise -> colorBuffer.variablesAvailable()
        runs -> expect(colorBuffer.getColorMarkers().length).toEqual(3)

      describe 'when a color marker is edited', ->
        [colorsUpdateSpy] = []

        beforeEach ->
          waitsForPromise -> colorBuffer.variablesAvailable()

          runs ->
            colorsUpdateSpy = jasmine.createSpy('did-update-color-markers')
            colorBuffer.onDidUpdateColorMarkers(colorsUpdateSpy)
            editBuffer '#336699', start: [1,13], end: [1,23]
            waitsFor -> colorsUpdateSpy.callCount > 0

        it 'updates the modified color marker', ->
          markers = colorBuffer.getColorMarkers()
          marker = markers[markers.length-1]
          expect(marker.color).toBeColor('#336699')

        it 'updates only the affected marker', ->
          expect(colorsUpdateSpy.argsForCall[0][0].destroyed.length).toEqual(1)
          expect(colorsUpdateSpy.argsForCall[0][0].created.length).toEqual(1)

        it 'removes the previous editor markers', ->
          expect(editor.findMarkers(type: 'pigments-color').length).toEqual(3)

      describe 'when a new color is added', ->
        [colorsUpdateSpy] = []

        beforeEach ->
          waitsForPromise -> colorBuffer.variablesAvailable()

          runs ->
            colorsUpdateSpy = jasmine.createSpy('did-update-color-markers')
            colorBuffer.onDidUpdateColorMarkers(colorsUpdateSpy)
            editor.moveToBottom()
            editBuffer '\n#336699'
            waitsFor -> colorsUpdateSpy.callCount > 0

        it 'adds a marker for the new color', ->
          markers = colorBuffer.getColorMarkers()
          marker = markers[markers.length-1]
          expect(markers.length).toEqual(4)
          expect(marker.color).toBeColor('#336699')
          expect(editor.findMarkers(type: 'pigments-color').length).toEqual(4)

        it 'dispatches the new marker in a did-update-color-markers event', ->
          expect(colorsUpdateSpy.argsForCall[0][0].destroyed.length).toEqual(0)
          expect(colorsUpdateSpy.argsForCall[0][0].created.length).toEqual(1)

      describe 'when a color marker is edited', ->
        [colorsUpdateSpy] = []

        beforeEach ->
          waitsForPromise -> colorBuffer.variablesAvailable()

          runs ->
            colorsUpdateSpy = jasmine.createSpy('did-update-color-markers')
            colorBuffer.onDidUpdateColorMarkers(colorsUpdateSpy)
            editBuffer '', start: [1,2], end: [1,23]
            waitsFor -> colorsUpdateSpy.callCount > 0

        it 'updates the modified color marker', ->
          expect(colorBuffer.getColorMarkers().length).toEqual(2)

        it 'updates only the affected marker', ->
          expect(colorsUpdateSpy.argsForCall[0][0].destroyed.length).toEqual(1)
          expect(colorsUpdateSpy.argsForCall[0][0].created.length).toEqual(0)

        it 'removes the previous editor markers', ->
          expect(editor.findMarkers(type: 'pigments-color').length).toEqual(2)

  describe 'when the editor is destroyed', ->
    it 'destroys the color buffer at the same time', ->
      editor.destroy()

      expect(project.colorBuffersByEditorId[editor.id]).toBeUndefined()
