fs = require 'fs'
path = require 'path'
ColorProject = require '../lib/color-project'
ProjectVariable = require '../lib/project-variable'

TOTAL_VARIABLES_IN_PROJECT = 12
TOTAL_COLORS_VARIABLES_IN_PROJECT = 10

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
      ignores: ['vendor/*']
    })

  describe '.deserialize', ->
    it 'restores the project in its previous state', ->
      data =
        root: rootPath
        timestamp: new Date().toJSON()

      jsonPath = path.resolve(__dirname, "./fixtures/base-project.json")
      json = fs.readFileSync(jsonPath).toString()
      json = json.replace /#\{(\w+)\}/g, (m,w) -> data[w]

      project = ColorProject.deserialize(JSON.parse(json))

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
      expect(project.variables).toBeDefined()
      expect(project.variables.length).toEqual(TOTAL_VARIABLES_IN_PROJECT)

    it 'dispatches a did-initialize event', ->
      expect(eventSpy).toHaveBeenCalled()

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
          buffers: {}
          ignores: ['vendor/*']
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
        spyOn(project, 'loadVariablesForPath').andCallThrough()

        waitsForPromise shouldReject: true, ->
          project.reloadVariablesForPath("#{rootPath}/styles/variables.styl")

      it 'returns a rejected promise', ->
        expect(project.loadVariablesForPath).not.toHaveBeenCalled()

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
          ignores: ['vendor/*']
          timestamp: date
          paths: [
            "#{rootPath}/styles/buttons.styl"
            "#{rootPath}/styles/variables.styl"
          ]
          buffers: {}
          variables: project.variables.map (v) -> v.serialize()
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

    describe '::getContext', ->
      it 'returns a context with the project variables', ->
        expect(project.getContext()).toBeDefined()
        expect(project.getContext().getVariablesCount()).toEqual(TOTAL_VARIABLES_IN_PROJECT)

    describe '::getPalette', ->
      it 'returns a palette with the colors from the project', ->
        expect(project.getPalette()).toBeDefined()
        expect(project.getPalette().getColorsCount()).toEqual(10)

    describe '::reloadVariablesForPath', ->
      describe 'for a file that is part of the loaded paths', ->
        beforeEach ->
          eventSpy = jasmine.createSpy('did-reload-file-variables')
          project.onDidReloadFileVariables(eventSpy)
          spyOn(project, 'deleteVariablesForPaths').andCallThrough()
          waitsForPromise -> project.reloadVariablesForPath("#{rootPath}/styles/variables.styl")

        it 'deletes the previous variables found for the file', ->
          expect(project.deleteVariablesForPaths).toHaveBeenCalled()

        it 'scans again the file to find variables', ->
          expect(project.variables.length).toEqual(TOTAL_VARIABLES_IN_PROJECT)

        it 'dispatches a did-reload-file-variables event', ->
          expect(eventSpy).toHaveBeenCalled()

    describe '::reloadVariablesForPaths', ->
      describe 'for a file that is part of the loaded paths', ->
        beforeEach ->
          eventSpy = jasmine.createSpy('did-reload-file-variables')
          project.onDidReloadFileVariables(eventSpy)
          spyOn(project, 'deleteVariablesForPaths').andCallThrough()
          waitsForPromise -> project.reloadVariablesForPaths([
            "#{rootPath}/styles/variables.styl"
            "#{rootPath}/styles/buttons.styl"
          ])

        it 'deletes the previous variables found for the file', ->
          expect(project.deleteVariablesForPaths).toHaveBeenCalled()

        it 'scans again the file to find variables', ->
          expect(project.variables.length).toEqual(TOTAL_VARIABLES_IN_PROJECT)

        it 'dispatches a did-reload-file-variables event', ->
          expect(eventSpy).toHaveBeenCalled()

      describe 'for a file that is not part of the loaded paths', ->
        beforeEach ->
          spyOn(project, 'loadVariablesForPath').andCallThrough()

          waitsForPromise shouldReject: true, ->
            project.reloadVariablesForPath("#{rootPath}/vendor/css/variables.less")

        it 'does nothing', ->
          expect(project.loadVariablesForPath).not.toHaveBeenCalled()

  ##    ########  ########  ######  ########  #######  ########  ########
  ##    ##     ## ##       ##    ##    ##    ##     ## ##     ## ##
  ##    ##     ## ##       ##          ##    ##     ## ##     ## ##
  ##    ########  ######    ######     ##    ##     ## ########  ######
  ##    ##   ##   ##             ##    ##    ##     ## ##   ##   ##
  ##    ##    ##  ##       ##    ##    ##    ##     ## ##    ##  ##
  ##    ##     ## ########  ######     ##     #######  ##     ## ########

  describe 'when restored', ->
    createProject = (params) ->
      data =
        root: params.root ? rootPath
        timestamp: params.timestamp?.toJSON() ? new Date().toJSON()
        editorId: params.editorId

      jsonPath = path.resolve(__dirname, params.stateFixture)
      json = fs.readFileSync(jsonPath).toString()
      json = json.replace /#\{(\w+)\}/g, (m,w) -> data[w]

      ColorProject.deserialize(JSON.parse(json))

    describe 'with a timestamp more recent than the files last modification date', ->
      beforeEach ->
        project = createProject
          stateFixture: "./fixtures/empty-project.json"

        waitsForPromise -> project.initialize()

      it 'does not rescans the files', ->
        expect(project.getVariables().length).toEqual(1)

    describe 'with a timestamp older than the files last modification date', ->
      beforeEach ->
        project = createProject
          timestamp: new Date(0)
          stateFixture: "./fixtures/empty-project.json"

        waitsForPromise -> project.initialize()

      it 'scans again all the files that have a more recent modification date', ->
        expect(project.getVariables().length).toEqual(TOTAL_VARIABLES_IN_PROJECT)

    describe 'with some files not saved in the project state', ->
      beforeEach ->
        project = createProject
          stateFixture: "./fixtures/partial-project.json"

        waitsForPromise -> project.initialize()

      it 'detects the new files and scans them', ->
        expect(project.getVariables().length).toEqual(12)

    describe 'with an open editor and the corresponding buffer state', ->
      [editor] = []
      beforeEach ->
        workspaceElement = atom.views.getView(atom.workspace)

        waitsForPromise ->
          atom.workspace.open('four-variables.styl').then (o) -> editor = o

        runs ->
          project = createProject
            stateFixture: "./fixtures/open-buffer-project.json"
            editorId: editor.id

      it 'restores the color buffer', ->
        expect(project.colorBuffersByEditorId[editor.id]).toBeDefined()
