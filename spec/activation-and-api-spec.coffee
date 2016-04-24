{Disposable} = require 'atom'
Pigments = require '../lib/pigments'
PigmentsAPI = require '../lib/pigments-api'
registry = require '../lib/variable-expressions'

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

    registry.createExpression 'pigments:txt_vars', '^[ \\t]*([a-zA-Z_$][a-zA-Z0-9\\-_]*)\\s*=(?!=)\\s*([^\\n\\r;]*);?$', ['txt']

    waitsForPromise label: 'pigments activation', ->
      atom.packages.activatePackage('pigments').then (pkg) ->
        pigments = pkg.mainModule
        project = pigments.getProject()

  afterEach ->
    registry.removeExpression 'pigments:txt_vars'
    project?.destroy()

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

  describe 'when deactivated', ->
    [editor, editorElement, colorBuffer] = []
    beforeEach ->
      waitsForPromise label: 'text-editor opened', ->
        atom.workspace.open('four-variables.styl').then (e) ->
          editor = e
          editorElement = atom.views.getView(e)
          colorBuffer = project.colorBufferForEditor(editor)

      waitsFor 'pigments markers appended to the DOM', ->
        editorElement.shadowRoot.querySelector('pigments-markers')

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

      waitsFor 'active pane item', ->
        item = atom.workspace.getActivePaneItem()
        item?

    it 'opens a settings view in the active pane', ->
      item.matches('pigments-color-project')

  ##       ###    ########  ####
  ##      ## ##   ##     ##  ##
  ##     ##   ##  ##     ##  ##
  ##    ##     ## ########   ##
  ##    ######### ##         ##
  ##    ##     ## ##         ##
  ##    ##     ## ##        ####

  describe 'API provider', ->
    [service, editor, editorElement, buffer] = []
    beforeEach ->
      waitsForPromise label: 'text-editor opened', ->
        atom.workspace.open('four-variables.styl').then (e) ->
          editor = e
          editorElement = atom.views.getView(e)
          buffer = project.colorBufferForEditor(editor)

      runs -> service = pigments.provideAPI()

      waitsForPromise label: 'project initialized', -> project.initialize()

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

      it 'calls the callback for every existing color buffer', ->
        expect(spy).toHaveBeenCalled()
        expect(spy.calls.length).toEqual(1)

      it 'calls the callback on every new buffer creation', ->
        waitsForPromise  label: 'text-editor opened', ->
          atom.workspace.open('buttons.styl')

        runs ->
          expect(spy.calls.length).toEqual(2)

  ##     ######   #######  ##        #######  ########   ######
  ##    ##    ## ##     ## ##       ##     ## ##     ## ##    ##
  ##    ##       ##     ## ##       ##     ## ##     ## ##
  ##    ##       ##     ## ##       ##     ## ########   ######
  ##    ##       ##     ## ##       ##     ## ##   ##         ##
  ##    ##    ## ##     ## ##       ##     ## ##    ##  ##    ##
  ##     ######   #######  ########  #######  ##     ##  ######

  describe 'color expression consumer', ->
    [colorProvider, consumerDisposable, editor, editorElement, colorBuffer, colorBufferElement, otherConsumerDisposable] = []
    beforeEach ->
      colorProvider =
        name: 'todo'
        regexpString: 'TODO'
        scopes: ['*']
        priority: 0
        handle: (match, expression, context) ->
          @red = 255

    afterEach ->
      consumerDisposable?.dispose()
      otherConsumerDisposable?.dispose()

    describe 'when consumed before opening a text editor', ->
      beforeEach ->
        consumerDisposable = pigments.consumeColorExpressions(colorProvider)

        waitsForPromise label: 'text-editor opened', ->
          atom.workspace.open('color-consumer-sample.txt').then (e) ->
            editor = e
            editorElement = atom.views.getView(e)
            colorBuffer = project.colorBufferForEditor(editor)

        waitsForPromise label: 'color buffer initialized', ->
          colorBuffer.initialize()
        waitsForPromise label: 'color buffer variables available', ->
          colorBuffer.variablesAvailable()

      it 'parses the new expression and renders a color', ->
        expect(colorBuffer.getColorMarkers().length).toEqual(1)

      it 'returns a Disposable instance', ->
        expect(consumerDisposable instanceof Disposable).toBeTruthy()

      describe 'the returned disposable', ->
        it 'removes the provided expression from the registry', ->
          consumerDisposable.dispose()

          expect(project.getColorExpressionsRegistry().getExpression('todo')).toBeUndefined()

        it 'triggers an update in the opened editors', ->
          updateSpy = jasmine.createSpy('did-update-color-markers')

          colorBuffer.onDidUpdateColorMarkers(updateSpy)
          consumerDisposable.dispose()

          waitsFor 'did-update-color-markers event dispatched', ->
            updateSpy.callCount > 0

          runs -> expect(colorBuffer.getColorMarkers().length).toEqual(0)

    describe 'when consumed after opening a text editor', ->
      beforeEach ->
        waitsForPromise label: 'text-editor opened', ->
          atom.workspace.open('color-consumer-sample.txt').then (e) ->
            editor = e
            editorElement = atom.views.getView(e)
            colorBuffer = project.colorBufferForEditor(editor)

        waitsForPromise label: 'color buffer initialized', ->
          colorBuffer.initialize()
        waitsForPromise label: 'color buffer variables available', ->
          colorBuffer.variablesAvailable()

      it 'triggers an update in the opened editors', ->
        updateSpy = jasmine.createSpy('did-update-color-markers')

        colorBuffer.onDidUpdateColorMarkers(updateSpy)
        consumerDisposable = pigments.consumeColorExpressions(colorProvider)

        waitsFor 'did-update-color-markers event dispatched', ->
          updateSpy.callCount > 0

        runs ->
          expect(colorBuffer.getColorMarkers().length).toEqual(1)

          consumerDisposable.dispose()

        waitsFor 'did-update-color-markers event dispatched', ->
          updateSpy.callCount > 1

        runs -> expect(colorBuffer.getColorMarkers().length).toEqual(0)

      describe 'when an array of expressions is passed', ->
        it 'triggers an update in the opened editors', ->
          updateSpy = jasmine.createSpy('did-update-color-markers')

          colorBuffer.onDidUpdateColorMarkers(updateSpy)
          consumerDisposable = pigments.consumeColorExpressions({
            expressions: [colorProvider]
          })

          waitsFor 'did-update-color-markers event dispatched', ->
            updateSpy.callCount > 0

          runs ->
            expect(colorBuffer.getColorMarkers().length).toEqual(1)

            consumerDisposable.dispose()

          waitsFor 'did-update-color-markers event dispatched', ->
            updateSpy.callCount > 1

          runs -> expect(colorBuffer.getColorMarkers().length).toEqual(0)

    describe 'when the expression matches a variable value', ->
      beforeEach ->
        waitsForPromise label: 'project initialized', ->
          project.initialize()

      it 'detects the new variable as a color variable', ->
        variableSpy = jasmine.createSpy('did-update-variables')

        project.onDidUpdateVariables(variableSpy)

        atom.config.set 'pigments.sourceNames', ['**/*.txt']

        waitsFor 'variables updated', -> variableSpy.callCount > 1

        runs ->
          expect(project.getVariables().length).toEqual(6)
          expect(project.getColorVariables().length).toEqual(4)

          consumerDisposable = pigments.consumeColorExpressions(colorProvider)

        waitsFor 'variables updated', -> variableSpy.callCount > 2

        runs ->
          expect(project.getVariables().length).toEqual(6)
          expect(project.getColorVariables().length).toEqual(5)

      describe 'and there was an expression that could not be resolved before', ->
        it 'updates the invalid color as a now valid color', ->
          variableSpy = jasmine.createSpy('did-update-variables')

          project.onDidUpdateVariables(variableSpy)

          atom.config.set 'pigments.sourceNames', ['**/*.txt']

          waitsFor 'variables updated', -> variableSpy.callCount > 1

          runs ->
            otherConsumerDisposable = pigments.consumeColorExpressions
              name: 'bar'
              regexpString: 'baz\\s+(\\w+)'
              handle: (match, expression, context) ->
                [_, expr] = match

                color = context.readColor(expr)

                return @invalid = true if context.isInvalid(color)

                @rgba = color.rgba

            consumerDisposable = pigments.consumeColorExpressions(colorProvider)

            waitsFor 'variables updated', -> variableSpy.callCount > 2

            runs ->
              expect(project.getVariables().length).toEqual(6)
              expect(project.getColorVariables().length).toEqual(6)
              expect(project.getVariableByName('bar').color.invalid).toBeFalsy()

              consumerDisposable.dispose()

            waitsFor 'variables updated', -> variableSpy.callCount > 3

            runs ->
              expect(project.getVariables().length).toEqual(6)
              expect(project.getColorVariables().length).toEqual(5)
              expect(project.getVariableByName('bar').color.invalid).toBeTruthy()

  ##    ##     ##    ###    ########   ######
  ##    ##     ##   ## ##   ##     ## ##    ##
  ##    ##     ##  ##   ##  ##     ## ##
  ##    ##     ## ##     ## ########   ######
  ##     ##   ##  ######### ##   ##         ##
  ##      ## ##   ##     ## ##    ##  ##    ##
  ##       ###    ##     ## ##     ##  ######

  describe 'variable expression consumer', ->
    [variableProvider, consumerDisposable, editor, editorElement, colorBuffer, colorBufferElement] = []

    beforeEach ->
      variableProvider =
        name: 'todo'
        regexpString: '(TODO):\\s*([^;\\n]+)'

      waitsForPromise label: 'project initialized', ->
        project.initialize()

    afterEach -> consumerDisposable?.dispose()

    it 'updates the project variables when consumed', ->
      variableSpy = jasmine.createSpy('did-update-variables')

      project.onDidUpdateVariables(variableSpy)

      atom.config.set 'pigments.sourceNames', ['**/*.txt']

      waitsFor 'variables updated', -> variableSpy.callCount > 1

      runs ->
        expect(project.getVariables().length).toEqual(6)
        expect(project.getColorVariables().length).toEqual(4)

        consumerDisposable = pigments.consumeVariableExpressions(variableProvider)

      waitsFor 'variables updated after service consumed', ->
        variableSpy.callCount > 2

      runs ->
        expect(project.getVariables().length).toEqual(7)
        expect(project.getColorVariables().length).toEqual(4)

        consumerDisposable.dispose()

      waitsFor 'variables updated after service disposed', ->
        variableSpy.callCount > 3

      runs ->
        expect(project.getVariables().length).toEqual(6)
        expect(project.getColorVariables().length).toEqual(4)

    describe 'when an array of expressions is passed', ->
      it 'updates the project variables when consumed', ->
        previousVariablesCount = null
        atom.config.set 'pigments.sourceNames', ['**/*.txt']

        waitsFor 'variables initialized', ->
          project.getVariables().length is 45

        runs ->
          previousVariablesCount = project.getVariables().length

        waitsFor 'variables updated', ->
          project.getVariables().length is 6

        runs ->
          expect(project.getVariables().length).toEqual(6)
          expect(project.getColorVariables().length).toEqual(4)

          previousVariablesCount = project.getVariables().length

          consumerDisposable = pigments.consumeVariableExpressions({
            expressions: [variableProvider]
          })

        waitsFor 'variables updated after service consumed', ->
          project.getVariables().length isnt previousVariablesCount

        runs ->
          expect(project.getVariables().length).toEqual(7)
          expect(project.getColorVariables().length).toEqual(4)

          previousVariablesCount = project.getVariables().length

          consumerDisposable.dispose()

        waitsFor 'variables updated after service disposed', ->
          project.getVariables().length isnt previousVariablesCount

        runs ->
          expect(project.getVariables().length).toEqual(6)
          expect(project.getColorVariables().length).toEqual(4)
