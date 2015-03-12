fs = require 'fs'
path = require 'path'
ColorProject = require '../lib/color-project'
ProjectVariable = require '../lib/project-variable'

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

      jsonPath = path.resolve(__dirname, "./fixtures/four-variables.json")
      json = fs.readFileSync(jsonPath).toString()
      json = json.replace /#\{(\w+)\}/g, (m,w) -> data[w]

      project = ColorProject.deserialize(JSON.parse(json))

      expect(project).toBeDefined()
      expect(project.getPaths()).toEqual([
        "#{rootPath}/styles/buttons.styl"
        "#{rootPath}/styles/variables.styl"
      ])
      expect(project.getVariables().length).toEqual(12)
      expect(project.getColorVariables().length).toEqual(10)

  describe '::loadPaths', ->
    beforeEach ->
      eventSpy = jasmine.createSpy('did-load-paths')
      project.onDidLoadPaths(eventSpy)

      promise = project.loadPaths().then (p) -> paths = p

      waitsForPromise -> promise

    it 'returns the paths for where to look for project variables', ->
      expect(paths).toEqual([
        "#{rootPath}/styles/buttons.styl"
        "#{rootPath}/styles/variables.styl"
      ])

    it 'dispatches a did-load-paths event', ->
      expect(eventSpy).toHaveBeenCalled()

  describe '::resetPaths', ->
    beforeEach ->
      promise = project.loadPaths()
      waitsForPromise -> promise

    it 'removes the cached loaded paths', ->
      project.resetPaths()

      expect(project.getPaths()).toBeUndefined()

  describe '::loadVariables', ->
    beforeEach ->
      eventSpy = jasmine.createSpy('did-load-variables')
      project.onDidLoadVariables(eventSpy)
      promise = project.loadVariables()
      waitsForPromise -> promise

    it 'scans the loaded paths to retrieve the variables', ->
      expect(project.variables).toBeDefined()
      expect(project.variables.length).toEqual(12)

    it 'dispatches a did-load-variables event', ->
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
          ignores: ['vendor/*']
        })

    describe '::getVariablesForFile', ->
      it 'returns undefined', ->
        expect(project.getVariablesForFile("#{rootPath}/styles/variables.styl")).toBeUndefined()

    describe '::getContext', ->
      it 'returns an empty context', ->
        expect(project.getContext()).toBeDefined()
        expect(project.getContext().getVariablesCount()).toEqual(0)

    describe '::getPalette', ->
      it 'returns an empty palette', ->
        expect(project.getPalette()).toBeDefined()
        expect(project.getPalette().getColorsCount()).toEqual(0)

    describe '::reloadVariablesForFile', ->
      beforeEach ->
        spyOn(project, 'deleteVariablesForFile').andCallThrough()
        spyOn(project, 'loadVariablesForFile').andCallThrough()

        waitsForPromise shouldReject: true, ->
          project.reloadVariablesForFile("#{rootPath}/styles/variables.styl")

      it 'returns a rejected promise', ->
        expect(project.deleteVariablesForFile).not.toHaveBeenCalled()
        expect(project.loadVariablesForFile).not.toHaveBeenCalled()

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
      waitsForPromise -> project.loadVariables()

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
          variables: project.variables.map (v) -> v.serialize()
        })

    describe '::getVariablesForFile', ->
      it 'returns the variables defined in the file', ->
        expect(project.getVariablesForFile("#{rootPath}/styles/variables.styl").length).toEqual(12)

      describe 'for a file that was ignored in the scanning process', ->
        it 'returns undefined', ->
          expect(project.getVariablesForFile("#{rootPath}/vendor/css/variables.less")).toEqual([])

    describe '::deleteVariablesForFile', ->
      it 'removes all the variables coming from the specified file', ->
        project.deleteVariablesForFile("#{rootPath}/styles/variables.styl")

        expect(project.getVariablesForFile("#{rootPath}/styles/variables.styl")).toEqual([])

      it 'destroys the removed variables', ->
        spyOn(ProjectVariable.prototype, 'destroy').andCallThrough()
        project.deleteVariablesForFile("#{rootPath}/styles/variables.styl")

        expect(ProjectVariable::destroy).toHaveBeenCalled()

    describe '::getContext', ->
      it 'returns a context with the project variables', ->
        expect(project.getContext()).toBeDefined()
        expect(project.getContext().getVariablesCount()).toEqual(12)

    describe '::getPalette', ->
      it 'returns a palette with the colors from the project', ->
        expect(project.getPalette()).toBeDefined()
        expect(project.getPalette().getColorsCount()).toEqual(10)

    describe '::reloadVariablesForFile', ->
      describe 'for a file that is part of the loaded paths', ->
        beforeEach ->
          eventSpy = jasmine.createSpy('did-reload-file-variables')
          project.onDidReloadFileVariables(eventSpy)
          spyOn(project, 'deleteVariablesForFile').andCallThrough()
          waitsForPromise -> project.reloadVariablesForFile("#{rootPath}/styles/variables.styl")

        it 'deletes the previous variables found for the file', ->
          expect(project.deleteVariablesForFile).toHaveBeenCalled()

        it 'scans again the file to find variables', ->
          expect(project.variables.length).toEqual(12)

        it 'dispatches a did-reload-file-variables event', ->
          expect(eventSpy).toHaveBeenCalled()

      describe 'for a file that is not part of the loaded paths', ->
        beforeEach ->
          spyOn(project, 'deleteVariablesForFile').andCallThrough()
          spyOn(project, 'loadVariablesForFile').andCallThrough()

          waitsForPromise shouldReject: true, ->
            project.reloadVariablesForFile("#{rootPath}/vendor/css/variables.less")

        it 'does nothing', ->
          expect(project.deleteVariablesForFile).not.toHaveBeenCalled()
          expect(project.loadVariablesForFile).not.toHaveBeenCalled()

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
        timestamp: params.timestamp.toJSON() ? new Date().toJSON()

      jsonPath = path.resolve(__dirname, "./fixtures/four-variables.json")
      json = fs.readFileSync(jsonPath).toString()
      json = json.replace /#\{(\w+)\}/g, (m,w) -> data[w]

      ColorProject.deserialize(JSON.parse(json))

    describe 'with a timestamp older than the files last modification date', ->
      beforeEach ->
        project = createProject timestamp: new Date(0)

      it '', ->
