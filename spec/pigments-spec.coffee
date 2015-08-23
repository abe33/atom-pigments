Pigments = require '../lib/pigments'
PigmentsAPI = require '../lib/pigments-api'

{SERIALIZE_VERSION, SERIALIZE_MARKERS_VERSION} = require '../lib/versions'

describe "Pigments", ->
  [workspaceElement, pigments, project] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    jasmine.attachToDOM(workspaceElement)

    atom.config.set('pigments.sourceNames', ['**/*.sass', '**/*.styl'])
    atom.config.set('pigments.ignoredNames', [])
    atom.config.set('pigments.ignoredScopes', [])
    atom.config.set('pigments.autocompleteScopes', [])

    waitsForPromise -> atom.packages.activatePackage('pigments').then (pkg) ->
      pigments = pkg.mainModule
      project = pigments.getProject()

  it 'instanciates a ColorProject instance', ->
    expect(pigments.getProject()).toBeDefined()

  it 'serializes the project', ->
    date = new Date
    spyOn(pigments.getProject(), 'getTimestamp').andCallFake -> date
    expect(pigments.serialize()).toEqual({
      project:
        deserializer: 'ColorProject'
        timestamp: date
        version: SERIALIZE_VERSION
        markersVersion: SERIALIZE_MARKERS_VERSION
        globalSourceNames: ['**/*.sass', '**/*.styl']
        globalIgnoredNames: []
        buffers: {}
    })

  describe 'service provider API', ->
    [service, editor, editorElement, buffer] = []
    beforeEach ->
      waitsForPromise -> atom.workspace.open('four-variables.styl').then (e) ->
        editor = e
        editorElement = atom.views.getView(e)
        buffer = project.colorBufferForEditor(editor)

      runs -> service = pigments.provideAPI()

      waitsForPromise -> project.initialize()

    it 'returns an object conforming to the API', ->
      expect(service instanceof PigmentsAPI).toBeTruthy()

      expect(service.getProject()).toBe(project)

      expect(service.getPalette()).toEqual(project.getPalette())
      expect(service.getPalette()).not.toBe(project.getPalette())

      expect(service.getVariables()).toEqual(project.getVariables())
      expect(service.getColorVariables()).toEqual(project.getColorVariables())

    describe '::observeColorBuffers', ->
      [spy] = []

      beforeEach ->
        spy = jasmine.createSpy('did-create-color-buffer')
        service.observeColorBuffers(spy)

      it 'calls the callback for every existing color buffers', ->
        expect(spy).toHaveBeenCalled()
        expect(spy.calls.length).toEqual(1)

      it 'calls the callback on every new buffer creation', ->
        waitsForPromise ->
          atom.workspace.open('buttons.styl')

        runs ->
          expect(spy.calls.length).toEqual(2)

  describe 'when deactivated', ->
    [editor, editorElement, colorBuffer] = []
    beforeEach ->
      waitsForPromise -> atom.workspace.open('four-variables.styl').then (e) ->
        editor = e
        editorElement = atom.views.getView(e)
        colorBuffer = project.colorBufferForEditor(editor)

      waitsFor -> editorElement.shadowRoot.querySelector('pigments-markers')

      runs ->
        spyOn(project, 'destroy').andCallThrough()
        spyOn(colorBuffer, 'destroy').andCallThrough()

        pigments.deactivate()

    it 'destroys the pigments project', ->
      expect(project.destroy).toHaveBeenCalled()

    it 'destroys all the color buffers that were created', ->
      expect(project.colorBufferForEditor(editor)).toBeUndefined()
      expect(project.colorBuffersByEditorId).toBeNull()
      expect(colorBuffer.destroy).toHaveBeenCalled()

    it 'destroys the color buffer element that were added to the DOM', ->
      expect(editorElement.shadowRoot.querySelector('pigments-markers')).not.toExist()

  describe 'pigments:project-settings', ->
    item = null
    beforeEach ->
      atom.commands.dispatch(workspaceElement, 'pigments:project-settings')

      waitsFor ->
        item = atom.workspace.getActivePaneItem()
        item?

    it 'opens a settings view in the active pane', ->
      item.matches('pigments-color-project')
