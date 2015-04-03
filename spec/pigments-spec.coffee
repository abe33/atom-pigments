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
    [editor] = []
    beforeEach ->
      waitsForPromise -> atom.workspace.open('four-variables.styl').then (e) ->
        editor = e

      runs ->
        spyOn(project, 'destroy').andCallThrough()
        atom.packages.deactivatePackage('pigments')

    it 'destroys the pigments project', ->
      expect(project.destroy).toHaveBeenCalled()
