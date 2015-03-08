ColorProject = require '../lib/color-project'

describe 'ColorProject', ->
  [project, promise, paths] = []

  beforeEach ->
    [fixturesPath] = atom.project.getPaths()
    atom.project.setPaths(["#{fixturesPath}/project"])

    project = new ColorProject({
      project: atom.project
      ignores: ['vendor/*']
    })

  describe '::loadPaths', ->
    beforeEach ->
      promise = project.loadPaths().then (p) -> paths = p

      waitsForPromise -> promise

    it 'returns the paths for where to look for project variables', ->
      expect(paths).toEqual([
        'styles/buttons.styl'
        'styles/variables.styl'
      ])
