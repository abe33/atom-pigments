ColorSearch = require '../lib/color-search'

describe 'ColorResultsElement', ->
  [search, resultsElement, pigments, project, completeSpy, findSpy] = []

  beforeEach ->
    atom.config.set 'pigments.sourceNames', [
      '**/*.styl'
      '**/*.less'
    ]

    waitsForPromise -> atom.packages.activatePackage('pigments').then (pkg) ->
      pigments = pkg.mainModule
      project = pigments.getProject()

    waitsForPromise -> project.initialize()

    runs ->
      search = project.findAllColors()
      spyOn(search, 'search').andCallThrough()
      completeSpy = jasmine.createSpy('did-complete-search')
      search.onDidCompleteSearch(completeSpy)

      resultsElement = atom.views.getView(search)

  afterEach -> waitsFor -> completeSpy.callCount > 0

  it 'is associated with ColorSearch model', ->
    expect(resultsElement).toBeDefined()

  it 'starts the search', ->
    expect(search.search).toHaveBeenCalled()

  describe 'when matches are found', ->
    beforeEach -> waitsFor -> completeSpy.callCount > 0

    it 'groups results by files', ->
      fileResults = resultsElement.querySelectorAll('.list-nested-item')

      expect(fileResults.length).toEqual(7)

      expect(fileResults[0].querySelectorAll('li.list-item').length).toEqual(3)
