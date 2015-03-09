ColorProject = require '../lib/color-project'

describe 'ColorProject', ->
  [project, promise, rootPath, paths] = []

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

  describe '::loadPaths', ->
    beforeEach ->
      promise = project.loadPaths().then (p) -> paths = p

      waitsForPromise -> promise

    it 'returns the paths for where to look for project variables', ->
      expect(paths).toEqual([
        "#{rootPath}/styles/buttons.styl"
        "#{rootPath}/styles/variables.styl"
      ])

    it 'stores the loaded paths for later use', ->
      expect(project.loadedPaths).toEqual([
        "#{rootPath}/styles/buttons.styl"
        "#{rootPath}/styles/variables.styl"
      ])

  describe '::resetPaths', ->
    beforeEach ->
      promise = project.loadPaths()
      waitsForPromise -> promise

    it 'removes the cached loaded paths', ->
      project.resetPaths()

      expect(project.loadedPaths).toBeUndefined()

  describe '::loadVariables', ->
    beforeEach ->
      promise = project.loadVariables()
      waitsForPromise -> promise

    it 'scans the loaded paths to retrieve the variables', ->
      expect(project.variables).toBeDefined()
      expect(project.variables.length).toEqual(12)

  describe 'when the variables have not been loaded yet', ->
    describe '::getVariablesForFile', ->
      it 'returns undefined', ->
        expect(project.getVariablesForFile('styles/variables.styl')).toBeUndefined()

    describe '::getContext', ->
      it 'returns an empty context', ->
        expect(project.getContext()).toBeDefined()
        expect(project.getContext().getVariablesCount()).toEqual(0)

    describe '::getPalette', ->
      it 'returns an empty palette', ->
        expect(project.getPalette()).toBeDefined()
        expect(project.getPalette().getColorsCount()).toEqual(0)

  describe 'when the variables have been loaded', ->
    beforeEach ->
      waitsForPromise -> project.loadVariables()

    describe '::getVariablesForFile', ->
      it 'returns the variables defined in the file', ->
        expect(project.getVariablesForFile('styles/variables.styl').length).toEqual(12)

      describe 'for a file that was ignored in the scanning process', ->
        it 'returns undefined', ->
          expect(project.getVariablesForFile('vendor/css/variables.less')).toEqual([])

    describe '::deleteVariablesForFile', ->
      it 'removes all the variables coming from the specified file', ->
        project.deleteVariablesForFile('styles/variables.styl')

        expect(project.getVariablesForFile('styles/variables.styl')).toEqual([])

    describe '::getContext', ->
      it 'returns a context with the project variables', ->
        expect(project.getContext()).toBeDefined()
        expect(project.getContext().getVariablesCount()).toEqual(12)

    describe '::getPalette', ->
      it 'returns a palette with the colors from the project', ->
        expect(project.getPalette()).toBeDefined()
        expect(project.getPalette().getColorsCount()).toEqual(10)
