ColorBuffer = require '../lib/color-buffer'

fdescribe 'ColorBuffer', ->
  [editor, colorBuffer, pigments, project] = []

  beforeEach ->
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
        updateSpy = jasmine.createSpy('did-update-markers')
        colorBuffer.onDidUpdateMarkers(updateSpy)
        waitsFor -> updateSpy.callCount > 0

      it 'replaces the invalid markers that are now valid', ->
        expect(colorBuffer.getValidColorMarkers().length).toEqual(4)
        expect(updateSpy.argsForCall[0][0].created.length).toEqual(1)
        expect(updateSpy.argsForCall[0][0].destroyed.length).toEqual(1)

      it 'destroys the text editor markers', ->
        expect(editor.findMarkers(type: 'pigments-color').length).toEqual(4)
        

  describe 'when the editor is destroyed', ->
    it 'destroys the color buffer at the same time', ->
      editor.destroy()

      expect(project.colorBuffersByEditorId[editor.id]).toBeUndefined()
