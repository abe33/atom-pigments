ColorBuffer = require '../lib/color-buffer'

describe 'ColorBuffer', ->
  [editor, colorBuffer, pigments, project] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    jasmine.attachToDOM(workspaceElement)

    waitsForPromise ->
      atom.workspace.open('four-variables.styl').then (o) -> editor = o

    waitsForPromise -> atom.packages.activatePackage('pigments').then (pkg) ->
      pigments = pkg.mainModule
      project = pigments.getProject()

  it 'creates a color buffer for each editor in the workspace', ->
    expect(project.colorBuffersByEditorId[editor.id]).toBeDefined()

  describe 'when the editor is destroyed', ->
    it 'destroys the color buffer at the same time', ->
      editor.destroy()

      expect(project.colorBuffersByEditorId[editor.id]).toBeUndefined()
