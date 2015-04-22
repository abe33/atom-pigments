fs = require 'fs'
path = require 'path'
ColorProject = require '../lib/color-project'
ColorBuffer = require '../lib/color-buffer'
ProjectVariable = require '../lib/project-variable'
jsonFixture = require('./spec-helper').jsonFixture(__dirname, 'fixtures')
require '../lib/register-elements'

TOTAL_VARIABLES_IN_PROJECT = 12
TOTAL_COLORS_VARIABLES_IN_PROJECT = 10
SERIALIZE_VERSION = "1.0.0"

describe 'ColorProject', ->
  [project, promise, rootPath, paths, eventSpy] = []

  beforeEach ->
    atom.config.set 'pigments.sourceNames', [
      '*.styl'
      '*.less'
    ]

    [fixturesPath] = atom.project.getPaths()
    rootPath = "#{fixturesPath}/project"
    atom.project.setPaths([rootPath])

    project = new ColorProject({
      ignoredNames: ['vendor/*']
    })

  describe '.deserialize', ->
    it 'restores the project in its previous state', ->
      data =
        root: rootPath
        timestamp: new Date().toJSON()
        version: SERIALIZE_VERSION

      json = jsonFixture 'base-project.json', data
      project = ColorProject.deserialize(json)

      expect(project).toBeDefined()
      expect(project.getPaths()).toEqual([
        "#{rootPath}/styles/buttons.styl"
        "#{rootPath}/styles/variables.styl"
      ])
      expect(project.getVariables().length).toEqual(TOTAL_VARIABLES_IN_PROJECT)
      expect(project.getColorVariables().length).toEqual(TOTAL_COLORS_VARIABLES_IN_PROJECT)

  describe '::initialize', ->
    beforeEach ->
      eventSpy = jasmine.createSpy('did-initialize')
      project.onDidInitialize(eventSpy)
      waitsForPromise -> project.initialize()

    it 'loads the paths to scan in the project', ->
      expect(project.getPaths()).toEqual([
        "#{rootPath}/styles/buttons.styl"
        "#{rootPath}/styles/variables.styl"
      ])

    it 'scans the loaded paths to retrieve the variables', ->
      expect(project.getVariables()).toBeDefined()
      expect(project.getVariables().length).toEqual(TOTAL_VARIABLES_IN_PROJECT)

    it 'dispatches a did-initialize event', ->
      expect(eventSpy).toHaveBeenCalled()

  describe '::findAllColors', ->
    it 'returns all the colors in the legibles files of the project', ->
      search = project.findAllColors()
      expect(search).toBeDefined()

  ##    ##     ##    ###    ########   ######     ##    ##  #######  ########
  ##    ##     ##   ## ##   ##     ## ##    ##    ###   ## ##     ##    ##
  ##    ##     ##  ##   ##  ##     ## ##          ####  ## ##     ##    ##
  ##    ##     ## ##     ## ########   ######     ## ## ## ##     ##    ##
  ##     ##   ##  ######### ##   ##         ##    ##  #### ##     ##    ##
  ##      ## ##   ##     ## ##    ##  ##    ##    ##   ### ##     ##    ##
  ##       ###    ##     ## ##     ##  ######     ##    ##  #######     ##
  ##
  ##    ##        #######     ###    ########  ######## ########
  ##    ##       ##     ##   ## ##   ##     ## ##       ##     ##
  ##    ##       ##     ##  ##   ##  ##     ## ##       ##     ##
  ##    ##       ##     ## ##     ## ##     ## ######   ##     ##
  ##    ##       ##     ## ######### ##     ## ##       ##     ##
  ##    ##       ##     ## ##     ## ##     ## ##       ##     ##
  ##    ########  #######  ##     ## ########  ######## ########

  describe 'when the variables have not been loaded yet', ->
    describe '::serialize', ->
      it 'returns an object without paths nor variables', ->
        date = new Date
        spyOn(project, 'getTimestamp').andCallFake -> date
        expect(project.serialize()).toEqual({
          deserializer: 'ColorProject'
          timestamp: date
          version: SERIALIZE_VERSION
          buffers: {}
          ignoredNames: ['vendor/*']
        })

    describe '::getVariablesForPath', ->
      it 'returns undefined', ->
        expect(project.getVariablesForPath("#{rootPath}/styles/variables.styl")).toBeUndefined()

    describe '::getContext', ->
      it 'returns an empty context', ->
        expect(project.getContext()).toBeDefined()
        expect(project.getContext().getVariablesCount()).toEqual(0)

    describe '::getPalette', ->
      it 'returns an empty palette', ->
        expect(project.getPalette()).toBeDefined()
        expect(project.getPalette().getColorsCount()).toEqual(0)

    describe '::reloadVariablesForPath', ->
      beforeEach ->
        spyOn(project, 'initialize').andCallThrough()

        waitsForPromise ->
          project.reloadVariablesForPath("#{rootPath}/styles/variables.styl")

      it 'returns a promise hooked on the initialize promise', ->
        expect(project.initialize).toHaveBeenCalled()

    describe '::setIgnoredNames', ->
      beforeEach ->
        project.setIgnoredNames([])

        waitsForPromise -> project.initialize()

      it 'initializes the project with the new paths', ->
        expect(project.getVariables().length).toEqual(32)

  ##    ##     ##    ###    ########   ######
  ##    ##     ##   ## ##   ##     ## ##    ##
  ##    ##     ##  ##   ##  ##     ## ##
  ##    ##     ## ##     ## ########   ######
  ##     ##   ##  ######### ##   ##         ##
  ##      ## ##   ##     ## ##    ##  ##    ##
  ##       ###    ##     ## ##     ##  ######
  ##
  ##    ##        #######     ###    ########  ######## ########
  ##    ##       ##     ##   ## ##   ##     ## ##       ##     ##
  ##    ##       ##     ##  ##   ##  ##     ## ##       ##     ##
  ##    ##       ##     ## ##     ## ##     ## ######   ##     ##
  ##    ##       ##     ## ######### ##     ## ##       ##     ##
  ##    ##       ##     ## ##     ## ##     ## ##       ##     ##
  ##    ########  #######  ##     ## ########  ######## ########

  describe 'when the variables have been loaded', ->
    beforeEach ->
      waitsForPromise -> project.initialize()

    describe '::serialize', ->
      it 'returns an object with project properties', ->
        date = new Date
        spyOn(project, 'getTimestamp').andCallFake -> date
        expect(project.serialize()).toEqual({
          deserializer: 'ColorProject'
          ignoredNames: ['vendor/*']
          timestamp: date
          version: SERIALIZE_VERSION
          paths: [
            "#{rootPath}/styles/buttons.styl"
            "#{rootPath}/styles/variables.styl"
          ]
          buffers: {}
          variables: project.getVariables().map (v) -> v.serialize()
        })

    describe '::getVariablesForPath', ->
      it 'returns the variables defined in the file', ->
        expect(project.getVariablesForPath("#{rootPath}/styles/variables.styl").length).toEqual(TOTAL_VARIABLES_IN_PROJECT)

      describe 'for a file that was ignored in the scanning process', ->
        it 'returns undefined', ->
          expect(project.getVariablesForPath("#{rootPath}/vendor/css/variables.less")).toEqual([])

    describe '::deleteVariablesForPath', ->
      it 'removes all the variables coming from the specified file', ->
        project.deleteVariablesForPath("#{rootPath}/styles/variables.styl")

        expect(project.getVariablesForPath("#{rootPath}/styles/variables.styl")).toEqual([])

      it 'destroys the removed variables', ->
        spyOn(ProjectVariable.prototype, 'destroy').andCallThrough()
        project.deleteVariablesForPath("#{rootPath}/styles/variables.styl")

        expect(ProjectVariable::destroy).toHaveBeenCalled()

      it 'debounces the calls to reloadVariablesForPath to perform one scan', ->
        waitsFor -> project.initialize()
        runs ->
          spyOn(project, 'reloadVariablesForPaths').andCallThrough()
          project.deleteVariablesForPath("#{rootPath}/styles/variables.styl")

        waitsFor -> project.reloadVariablesForPaths.callCount > 0
        runs -> expect(project.reloadVariablesForPaths.callCount).toEqual(1)

    describe '::getContext', ->
      it 'returns a context with the project variables', ->
        expect(project.getContext()).toBeDefined()
        expect(project.getContext().getVariablesCount()).toEqual(TOTAL_VARIABLES_IN_PROJECT)

    describe '::getPalette', ->
      it 'returns a palette with the colors from the project', ->
        expect(project.getPalette()).toBeDefined()
        expect(project.getPalette().getColorsCount()).toEqual(10)

    describe '::showVariableInFile', ->
      it 'opens the file where is located the variable', ->
        spy = jasmine.createSpy('did-add-text-editor')
        atom.workspace.onDidAddTextEditor(spy)

        project.showVariableInFile(project.getVariables()[0])

        waitsFor -> spy.callCount > 0

        runs ->
          editor = atom.workspace.getActiveTextEditor()

          expect(editor.getSelectedBufferRange()).toEqual([[1,2],[1,14]])

    describe '::reloadVariablesForPath', ->
      describe 'for a file that is part of the loaded paths', ->
        describe 'where the reload finds new variables', ->
          beforeEach ->
            project.deleteVariablesForPath("#{rootPath}/styles/variables.styl")

            eventSpy = jasmine.createSpy('did-update-variables')
            project.onDidUpdateVariables(eventSpy)
            waitsForPromise -> project.reloadVariablesForPath("#{rootPath}/styles/variables.styl")

          it 'scans again the file to find variables', ->
            expect(project.getVariables().length).toEqual(TOTAL_VARIABLES_IN_PROJECT)

          it 'dispatches a did-update-variables event', ->
            expect(eventSpy).toHaveBeenCalled()

        describe 'where the reload finds nothing new', ->
          beforeEach ->
            eventSpy = jasmine.createSpy('did-update-variables')
            project.onDidUpdateVariables(eventSpy)
            waitsForPromise -> project.reloadVariablesForPath("#{rootPath}/styles/variables.styl")

          it 'leaves the file variables intact', ->
            expect(project.getVariables().length).toEqual(TOTAL_VARIABLES_IN_PROJECT)

          it 'does not dispatch a did-update-variables event', ->
            expect(eventSpy).not.toHaveBeenCalled()

    describe '::reloadVariablesForPaths', ->
      describe 'for a file that is part of the loaded paths', ->
        describe 'where the reload finds new variables', ->
          beforeEach ->
            project.deleteVariablesForPaths([
              "#{rootPath}/styles/variables.styl", "#{rootPath}/styles/buttons.styl"
            ])
            eventSpy = jasmine.createSpy('did-update-variables')
            project.onDidUpdateVariables(eventSpy)
            waitsForPromise -> project.reloadVariablesForPaths([
              "#{rootPath}/styles/variables.styl"
              "#{rootPath}/styles/buttons.styl"
            ])

          it 'scans again the file to find variables', ->
            expect(project.getVariables().length).toEqual(TOTAL_VARIABLES_IN_PROJECT)

          it 'dispatches a did-update-variables event', ->
            expect(eventSpy).toHaveBeenCalled()

        describe 'where the reload finds nothing new', ->
          beforeEach ->
            eventSpy = jasmine.createSpy('did-update-variables')
            project.onDidUpdateVariables(eventSpy)
            waitsForPromise -> project.reloadVariablesForPaths([
              "#{rootPath}/styles/variables.styl"
              "#{rootPath}/styles/buttons.styl"
            ])

          it 'leaves the file variables intact', ->
            expect(project.getVariables().length).toEqual(TOTAL_VARIABLES_IN_PROJECT)

          it 'does not dispatch a did-update-variables event', ->
            expect(eventSpy).not.toHaveBeenCalled()

      describe 'for a file that is not part of the loaded paths', ->
        beforeEach ->
          spyOn(project, 'loadVariablesForPath').andCallThrough()

          waitsForPromise ->
            project.reloadVariablesForPath("#{rootPath}/vendor/css/variables.less")

        it 'does nothing', ->
          expect(project.loadVariablesForPath).not.toHaveBeenCalled()

    describe 'when a buffer with variables is open', ->
      [editor, colorBuffer] = []
      beforeEach ->
        eventSpy = jasmine.createSpy('did-update-variables')
        project.onDidUpdateVariables(eventSpy)

        waitsForPromise ->
          atom.workspace.open('styles/variables.styl').then (o) -> editor = o

        runs ->
          colorBuffer = project.colorBufferForEditor(editor)
          spyOn(colorBuffer, 'scanBufferForVariables').andCallThrough()

        waitsForPromise -> project.initialize()
        waitsForPromise -> colorBuffer.variablesAvailable()

      it 'updates the project variable with the buffer ranges', ->
        for variable in project.getVariables()
          expect(variable.bufferRange).toBeDefined()

      describe 'when a color is modified and affects other variables ranges', ->
        [variablesTextRanges] = []
        beforeEach ->
          runs ->
            variablesTextRanges = {}
            colorBuffer.getVariableMarkers().forEach (marker) ->
              variablesTextRanges[marker.variable.name] = marker.variable.range

            editor.setSelectedBufferRange([[1,7],[1,14]])
            editor.insertText('#336')
            editor.getBuffer().emitter.emit('did-stop-changing')

          waitsFor -> eventSpy.callCount > 0

        it 'reloads the variables with the buffer instead of the file', ->
          expect(colorBuffer.scanBufferForVariables).toHaveBeenCalled()
          expect(project.getVariables().length).toEqual(TOTAL_VARIABLES_IN_PROJECT)

        it 'uses the buffer ranges to detect which variables were really changed', ->
          expect(eventSpy.argsForCall[0][0].destroyed.length).toEqual(1)
          expect(eventSpy.argsForCall[0][0].created.length).toEqual(1)

        it 'updates the text range of the other variables', ->
          project.getVariablesForPath("#{rootPath}/styles/variables.styl").forEach (variable) ->
            if variable.name isnt 'colors.red'
              expect(variable.range[0]).toEqual(variablesTextRanges[variable.name][0] - 3)
              expect(variable.range[1]).toEqual(variablesTextRanges[variable.name][1] - 3)

        it 'dispatches a did-update-variables event', ->
          expect(eventSpy).toHaveBeenCalled()

    describe '::setIgnoredNames', ->
      describe 'with an empty array', ->
        beforeEach ->
          expect(project.getVariables().length).toEqual(12)

          spy = jasmine.createSpy 'did-update-variables'
          project.onDidUpdateVariables(spy)
          project.setIgnoredNames([])

          waitsFor -> spy.callCount > 0

        it 'reloads the variables from the new paths', ->
          expect(project.getVariables().length).toEqual(32)

      describe 'with a more restrictive array', ->
        beforeEach ->
          expect(project.getVariables().length).toEqual(12)

          spy = jasmine.createSpy 'did-update-variables'
          project.onDidUpdateVariables(spy)
          project.setIgnoredNames(['vendor/*', '**/*.styl'])

          waitsFor -> spy.callCount > 0

        it 'clears all the variables as there is no legible paths', ->
          expect(project.getPaths().length).toEqual(0)
          expect(project.getVariables().length).toEqual(0)


  ##    ########  ########  ######  ########  #######  ########  ########
  ##    ##     ## ##       ##    ##    ##    ##     ## ##     ## ##
  ##    ##     ## ##       ##          ##    ##     ## ##     ## ##
  ##    ########  ######    ######     ##    ##     ## ########  ######
  ##    ##   ##   ##             ##    ##    ##     ## ##   ##   ##
  ##    ##    ##  ##       ##    ##    ##    ##     ## ##    ##  ##
  ##    ##     ## ########  ######     ##     #######  ##     ## ########

  describe 'when restored', ->
    createProject = (params={}) ->
      {stateFixture} = params
      delete params.stateFixture

      params.root ?= rootPath
      params.timestamp ?=  new Date().toJSON()
      params.variableMarkers ?= [1..12]
      params.colorMarkers ?= [13..24]
      params.version ?= SERIALIZE_VERSION

      ColorProject.deserialize(jsonFixture(stateFixture, params))

    describe 'with a timestamp more recent than the files last modification date', ->
      beforeEach ->
        project = createProject
          stateFixture: "empty-project.json"

        waitsForPromise -> project.initialize()

      it 'does not rescans the files', ->
        expect(project.getVariables().length).toEqual(1)

    describe 'with a version different that the current one', ->
      beforeEach ->
        project = createProject
          stateFixture: "empty-project.json"
          version: "0.0.0"

        waitsForPromise -> project.initialize()

      it 'drops the whole serialized state and rescans all the project', ->
        expect(project.getVariables().length).toEqual(32)

    describe 'with a timestamp older than the files last modification date', ->
      beforeEach ->
        project = createProject
          timestamp: new Date(0).toJSON()
          stateFixture: "empty-project.json"

        waitsForPromise -> project.initialize()

      it 'scans again all the files that have a more recent modification date', ->
        expect(project.getVariables().length).toEqual(TOTAL_VARIABLES_IN_PROJECT)

    describe 'with some files not saved in the project state', ->
      beforeEach ->
        project = createProject
          stateFixture: "partial-project.json"

        waitsForPromise -> project.initialize()

      it 'detects the new files and scans them', ->
        expect(project.getVariables().length).toEqual(12)

    describe 'with an open editor and the corresponding buffer state', ->
      [editor, colorBuffer] = []
      beforeEach ->
        waitsForPromise ->
          atom.workspace.open('variables.styl').then (o) -> editor = o

        runs ->
          project = createProject
            stateFixture: "open-buffer-project.json"
            id: editor.id

          spyOn(ColorBuffer.prototype, 'variablesAvailable').andCallThrough()

        runs -> colorBuffer = project.colorBuffersByEditorId[editor.id]

      it 'restores the color buffer in its previous state', ->
        expect(colorBuffer).toBeDefined()
        expect(colorBuffer.getVariableMarkers().length).toEqual(TOTAL_VARIABLES_IN_PROJECT)
        expect(colorBuffer.getColorMarkers().length).toEqual(TOTAL_COLORS_VARIABLES_IN_PROJECT)

      it 'does not wait for the project variables', ->
        expect(colorBuffer.variablesAvailable).not.toHaveBeenCalled()

    describe 'with an open editor, the corresponding buffer state and a old timestamp', ->
      [editor, colorBuffer] = []
      beforeEach ->
        waitsForPromise ->
          atom.workspace.open('variables.styl').then (o) -> editor = o

        runs ->
          spyOn(ColorBuffer.prototype, 'updateVariableMarkers').andCallThrough()
          project = createProject
            timestamp: new Date(0).toJSON()
            stateFixture: "open-buffer-project.json"
            id: editor.id

        runs -> colorBuffer = project.colorBuffersByEditorId[editor.id]

        waitsFor -> colorBuffer.updateVariableMarkers.callCount > 0

      it 'invalidates the color buffer markers as soon as the dirty paths have been determined', ->
        expect(colorBuffer.updateVariableMarkers).toHaveBeenCalled()
