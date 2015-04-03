Pigments = require '../lib/pigments'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "Pigments", ->
  [workspaceElement, pigments, project] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    jasmine.attachToDOM(workspaceElement)

    waitsForPromise -> atom.packages.activatePackage('pigments').then (pkg) ->
      pigments = pkg.mainModule
      project = pigments.getProject()

  it 'instanciates a ColorProject instance', ->
    expect(pigments.getProject()).toBeDefined()

  it 'serializes the project', ->
    date = new Date
    spyOn(pigments.getProject(), 'getTimestamp').andCallFake -> date
    expect(pigments.serialize()).toEqual({
      deserializer: 'ColorProject'
      timestamp: date
      buffers: {}
    })

  describe 'when deactivated', ->
    [editor, editorElement, buffer] = []
    beforeEach ->
      waitsForPromise -> atom.workspace.open('four-variables.styl').then (e) ->
        editor = e
        editorElement = atom.views.getView(e)
        buffer = project.colorBufferForEditor(editor)

      waitsFor -> editorElement.shadowRoot.querySelector('pigments-markers')

      runs ->
        spyOn(project, 'destroy').andCallThrough()
        spyOn(buffer, 'destroy').andCallThrough()

        pigments.deactivate()

    it 'destroys the pigments project', ->
      expect(project.destroy).toHaveBeenCalled()

    it 'destroys all the buffer that were created', ->
      expect(project.colorBufferForEditor(editor)).toBeUndefined()
      expect(project.colorBuffersByEditorId).toBeNull()
      expect(buffer.destroy).toHaveBeenCalled()

    it 'destroys the buffer element that were added to the DOM', ->
      expect(editorElement.shadowRoot.querySelector('pigments-markers')).not.toExist()
