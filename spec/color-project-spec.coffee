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
