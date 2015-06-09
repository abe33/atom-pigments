fs = require 'fs'
path = require 'path'

{SERIALIZE_VERSION, SERIALIZE_MARKERS_VERSION} = require '../lib/versions'
ColorProject = require '../lib/color-project'
ColorBuffer = require '../lib/color-buffer'
ProjectVariable = require '../lib/project-variable'
jsonFixture = require('./spec-helper').jsonFixture(__dirname, 'fixtures')
require '../lib/register-elements'
{click} = require './helpers/events'

TOTAL_VARIABLES_IN_PROJECT = 12
TOTAL_COLORS_VARIABLES_IN_PROJECT = 10


describe 'ColorProject', ->
  [project, promise, rootPath, paths, eventSpy] = []

  beforeEach ->
    atom.config.set 'pigments.sourceNames', [
      '*.styl'
      '*.less'
    ]
    atom.config.set 'pigments.ignoredNames', []

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
        markersVersion: SERIALIZE_MARKERS_VERSION

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
        expected = {
          deserializer: 'ColorProject'
          timestamp: date
          version: SERIALIZE_VERSION
          markersVersion: SERIALIZE_MARKERS_VERSION
          globalSourceNames: ['*.styl', '*.less']
          globalIgnoredNames: []
          ignoredNames: ['vendor/*']
          buffers: {}
        }
        expect(project.serialize()).toEqual(expected)

    describe '::getVariablesForPath', ->
      it 'returns undefined', ->
        expect(project.getVariablesForPath("#{rootPath}/styles/variables.styl")).toEqual([])

    describe '::getVariableByName', ->
      it 'returns undefined', ->
        expect(project.getVariableByName("foo")).toBeUndefined()

    describe '::getVariableById', ->
      it 'returns undefined', ->
        expect(project.getVariableById(0)).toBeUndefined()

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

  describe 'when the project has no variables source files', ->
    beforeEach ->
      atom.config.set 'pigments.sourceNames', ['*.sass']

      [fixturesPath] = atom.project.getPaths()
      rootPath = "#{fixturesPath}/project-no-sources"
      atom.project.setPaths([rootPath])

      project = new ColorProject({})

      waitsForPromise -> project.initialize()

    it 'initializes the paths with an empty array', ->
      expect(project.getPaths()).toEqual([])

    it 'initializes the variables with an empty array', ->
      expect(project.getVariables()).toEqual([])

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
          markersVersion: SERIALIZE_MARKERS_VERSION
          paths: [
            "#{rootPath}/styles/buttons.styl"
            "#{rootPath}/styles/variables.styl"
          ]
          globalSourceNames: ['*.styl', '*.less']
          globalIgnoredNames: []
          buffers: {}
          variables: project.variables.serialize()
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

      describe 'when a color is modified that does not affect other variables ranges', ->
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
          expect(eventSpy.argsForCall[0][0].destroyed).toBeUndefined()
          expect(eventSpy.argsForCall[0][0].created).toBeUndefined()
          expect(eventSpy.argsForCall[0][0].updated.length).toEqual(1)

        it 'updates the text range of the other variables', ->
          project.getVariablesForPath("#{rootPath}/styles/variables.styl").forEach (variable) ->
            if variable.name isnt 'colors.red'
              expect(variable.range[0]).toEqual(variablesTextRanges[variable.name][0] - 3)
              expect(variable.range[1]).toEqual(variablesTextRanges[variable.name][1] - 3)

        it 'dispatches a did-update-variables event', ->
          expect(eventSpy).toHaveBeenCalled()

      describe 'when a text is inserted that affects other variables ranges', ->
        [variablesTextRanges, variablesBufferRanges] = []
        beforeEach ->
          runs ->
            variablesTextRanges = {}
            variablesBufferRanges = {}
            colorBuffer.getVariableMarkers().forEach (marker) ->
              variablesTextRanges[marker.variable.name] = marker.variable.range
              variablesBufferRanges[marker.variable.name] = marker.variable.bufferRange

            spyOn(project.variables, 'addMany').andCallThrough()

            editor.setSelectedBufferRange([[0,0],[0,0]])
            editor.insertText('\n\n')
            editor.getBuffer().emitter.emit('did-stop-changing')

          waitsFor -> project.variables.addMany.callCount > 0

        it 'does not trigger a change event', ->
          expect(eventSpy.callCount).toEqual(0)

        it 'updates the range of the updated variables', ->
          project.getVariablesForPath("#{rootPath}/styles/variables.styl").forEach (variable) ->
            if variable.name isnt 'colors.red'
              expect(variable.range[0]).toEqual(variablesTextRanges[variable.name][0] + 2)
              expect(variable.range[1]).toEqual(variablesTextRanges[variable.name][1] + 2)
              expect(variable.bufferRange.isEqual(variablesBufferRanges[variable.name])).toBeFalsy()

      describe 'when a color is removed', ->
        [variablesTextRanges] = []
        beforeEach ->
          runs ->
            variablesTextRanges = {}
            colorBuffer.getVariableMarkers().forEach (marker) ->
              variablesTextRanges[marker.variable.name] = marker.variable.range

            editor.setSelectedBufferRange([[1,0],[2,0]])
            editor.insertText('')
            editor.getBuffer().emitter.emit('did-stop-changing')

          waitsFor -> eventSpy.callCount > 0

        it 'reloads the variables with the buffer instead of the file', ->
          expect(colorBuffer.scanBufferForVariables).toHaveBeenCalled()
          expect(project.getVariables().length).toEqual(TOTAL_VARIABLES_IN_PROJECT - 1)

        it 'uses the buffer ranges to detect which variables were really changed', ->
          expect(eventSpy.argsForCall[0][0].destroyed.length).toEqual(1)
          expect(eventSpy.argsForCall[0][0].created).toBeUndefined()
          expect(eventSpy.argsForCall[0][0].updated).toBeUndefined()

        it 'can no longer be found in the project variables', ->
          expect(project.getVariables().some (v) -> v.name is 'colors.red').toBeFalsy()
          expect(project.getColorVariables().some (v) -> v.name is 'colors.red').toBeFalsy()

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

    ##     ######  ######## ######## ######## #### ##    ##  ######    ######
    ##    ##    ## ##          ##       ##     ##  ###   ## ##    ##  ##    ##
    ##    ##       ##          ##       ##     ##  ####  ## ##        ##
    ##     ######  ######      ##       ##     ##  ## ## ## ##   ####  ######
    ##          ## ##          ##       ##     ##  ##  #### ##    ##        ##
    ##    ##    ## ##          ##       ##     ##  ##   ### ##    ##  ##    ##
    ##     ######  ########    ##       ##    #### ##    ##  ######    ######

    describe 'when the sourceNames setting is changed', ->
      [updateSpy] = []

      beforeEach ->
        originalPaths = project.getPaths()
        atom.config.set 'pigments.sourceNames', []

        waitsFor -> project.getPaths().join(',') isnt originalPaths.join(',')

      it 'updates the variables using the new pattern', ->
        expect(project.getVariables().length).toEqual(0)

      describe 'so that new paths are found', ->
        beforeEach ->
          updateSpy = jasmine.createSpy('did-update-variables')

          originalPaths = project.getPaths()
          project.onDidUpdateVariables(updateSpy)

          atom.config.set 'pigments.sourceNames', ['**/*.styl']

          waitsFor -> project.getPaths().join(',') isnt originalPaths.join(',')
          waitsFor -> updateSpy.callCount > 0

        it 'loads the variables from these new paths', ->
          expect(project.getVariables().length).toEqual(TOTAL_VARIABLES_IN_PROJECT)

    describe 'when the ignoredNames setting is changed', ->
      [updateSpy] = []

      beforeEach ->
        originalPaths = project.getPaths()
        atom.config.set 'pigments.ignoredNames', ['**/*.styl']

        waitsFor -> project.getPaths().join(',') isnt originalPaths.join(',')

      it 'updates the found using the new pattern', ->
        expect(project.getVariables().length).toEqual(0)

      describe 'so that new paths are found', ->
        beforeEach ->
          updateSpy = jasmine.createSpy('did-update-variables')

          originalPaths = project.getPaths()
          project.onDidUpdateVariables(updateSpy)

          atom.config.set 'pigments.ignoredNames', []

          waitsFor -> project.getPaths().join(',') isnt originalPaths.join(',')
          waitsFor -> updateSpy.callCount > 0

        it 'loads the variables from these new paths', ->
          expect(project.getVariables().length).toEqual(TOTAL_VARIABLES_IN_PROJECT)

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
      params.markersVersion ?= SERIALIZE_MARKERS_VERSION

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

    describe 'with a sourceNames setting value different than when serialized', ->
      beforeEach ->
        atom.config.set('pigments.sourceNames', [])

        project = createProject
          stateFixture: "empty-project.json"

        waitsForPromise -> project.initialize()

      it 'drops the whole serialized state and rescans all the project', ->
        expect(project.getVariables().length).toEqual(0)

    describe 'with a markers version different that the current one', ->
      beforeEach ->
        project = createProject
          stateFixture: "empty-project.json"
          markersVersion: "0.0.0"

        waitsForPromise -> project.initialize()

      it 'keeps the project related data', ->
        expect(project.ignoredNames).toEqual(['vendor/*'])
        expect(project.getPaths()).toEqual([
          "#{rootPath}/styles/buttons.styl",
          "#{rootPath}/styles/variables.styl"
        ])

      it 'drops the variables and buffers data', ->
        expect(project.getVariables().length).toEqual(TOTAL_VARIABLES_IN_PROJECT)

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

##     ######   ##     ##    ###    ########  ########
##    ##    ##  ##     ##   ## ##   ##     ## ##     ##
##    ##        ##     ##  ##   ##  ##     ## ##     ##
##    ##   #### ##     ## ##     ## ########  ##     ##
##    ##    ##  ##     ## ######### ##   ##   ##     ##
##    ##    ##  ##     ## ##     ## ##    ##  ##     ##
##     ######    #######  ##     ## ##     ## ########

describe 'ColorProject', ->
  describe 'with a number of files greater than the threshold', ->
    [project, workspaceElement, promise, rootPath, popup, promiseSpy] = []

    beforeEach ->

      atom.config.set 'pigments.sourcesWarningThreshold', 5
      atom.config.set 'pigments.sourceNames', ['*.sass']

      [fixturesPath] = atom.project.getPaths()
      rootPath = "#{fixturesPath}/project-out-of-bounds"
      atom.project.setPaths([rootPath])

      workspaceElement = atom.views.getView(atom.workspace)
      workspaceElement.style.height = "600px"
      jasmine.attachToDOM(workspaceElement)

      project = new ColorProject({})

    describe '::initialize', ->
      beforeEach ->
        promiseSpy = jasmine.createSpy('project.initialize')
        promise = project.initialize()
        promise.then(promiseSpy)

        waitsFor ->
          popup = workspaceElement.querySelector('pigments-sources-popup')

      it 'pauses after the paths loading and asks the user for choice', ->
        expect(promiseSpy).not.toHaveBeenCalled()

      describe 'when the warning popup is opened', ->
        describe 'clicking on the ignore warning button', ->
          beforeEach ->
            click(popup.ignoreButton)

            waitsFor -> promiseSpy.callCount > 0

          it 'ignores the warning and uses all the paths', ->
            expect(project.getPaths().length).toEqual(6)

          it 'closes the popup', ->
            expect(popup.parentNode).toBeNull()

        describe 'clicking on the drop paths button', ->
          beforeEach ->
            click(popup.dropPathsButton)

            waitsFor -> promiseSpy.callCount > 0

          it 'ignores the loaded paths and uses an empty array instead', ->
            expect(project.getPaths().length).toEqual(0)

          it 'closes the popup', ->
            expect(popup.parentNode).toBeNull()

        describe 'clicking on the add ignore rules button', ->
          [list] = []

          beforeEach ->
            click(popup.addIgnoreRuleButton)

            waitsFor -> list = popup.querySelector('.list-group:not(:empty)')

          it 'opens a list containing all the paths', ->
            expect(list.children.length).toEqual(6)

          describe 'then clicking on the validate paths buttons', ->
            beforeEach ->
              click(popup.validatePathsButton)

              waitsFor -> promiseSpy.callCount > 0

            it 'resolve the promise with the active paths', ->
              expect(promiseSpy.argsForCall[0][0].length).toEqual(6)

            it 'closes the popup', ->
              expect(popup.parentNode).toBeNull()

          describe 'writing a rule in the mini editor', ->
            beforeEach ->
              popup.ignoreRulesEditor.insertText('*-5.sass, *-6.sass')
              popup.ignoreRulesEditor.getBuffer().emitter.emit('did-stop-changing')

            it 'updates the list to display which paths are ignored', ->
              expect(popup.querySelectorAll('li.active').length).toEqual(4)

            describe 'then clicking on the validate paths buttons', ->
              beforeEach ->
                click(popup.validatePathsButton)

                waitsFor -> promiseSpy.callCount > 0

              it 'resolve the promise with the active paths', ->
                expect(promiseSpy.argsForCall[0][0].length).toEqual(4)

          describe 'writing an invalid rule in the editor', ->
            beforeEach ->
              popup.ignoreRulesEditor.insertText(', +(')
              popup.ignoreRulesEditor.getBuffer().emitter.emit('did-stop-changing')

            it 'ignores the invalid rules', ->
              expect(popup.querySelectorAll('li.active').length).toEqual(6)

##    ########  ######## ########    ###    ##     ## ##       ########
##    ##     ## ##       ##         ## ##   ##     ## ##          ##
##    ##     ## ##       ##        ##   ##  ##     ## ##          ##
##    ##     ## ######   ######   ##     ## ##     ## ##          ##
##    ##     ## ##       ##       ######### ##     ## ##          ##
##    ##     ## ##       ##       ##     ## ##     ## ##          ##
##    ########  ######## ##       ##     ##  #######  ########    ##

xdescribe 'ColorProject', ->
  [project, rootPath] = []
  describe 'when the project has a pigments defaults file', ->
    beforeEach ->
      atom.config.set 'pigments.sourceNames', ['*.sass']

      [fixturesPath] = atom.project.getPaths()
      rootPath = "#{fixturesPath}/project-with-defaults"
      atom.project.setPaths([rootPath])

      project = new ColorProject({})

      waitsForPromise -> project.initialize()

    it 'uses the defaults in the .pigments file in priority', ->
      expect(project.getColorVariables().length).toEqual(4)
      expect(project.getVariableByName('$button-color').getColor()).toBeColor(255,255,255,1)
