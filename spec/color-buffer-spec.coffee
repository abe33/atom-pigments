ColorBuffer = require '../lib/color-buffer'

describe 'ColorBuffer', ->
  [editor, colorBuffer, pigments, project] = []

  editBuffer = (text, options) ->

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
        waitsFor -> updateSpy.callCount > 0

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
        beforeEach ->
          updateSpy = jasmine.createSpy('did-update-variable-markers')
          colorBuffer.onDidUpdateVariableMarkers(updateSpy)
          editBuffer '#336699', start: [0,13], end: [0,17]
          waitsFor -> updateSpy.callCount > 0

        it 'updates the modified variable marker', ->
          expect(colorBuffer.getVariableMarkers()[0].variable.value).toEqual('#336699')

        it 'has the same number of variables than before', ->
          expect(colorBuffer.getVariableMarkers().length).toEqual(4)
          expect(editor.findMarkers(type: 'pigments-variable').length).toEqual(4)

  describe 'when the editor is destroyed', ->
    it 'destroys the color buffer at the same time', ->
      editor.destroy()

      expect(project.colorBuffersByEditorId[editor.id]).toBeUndefined()
