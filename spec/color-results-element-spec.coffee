{click} = require './helpers/events'
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

      jasmine.attachToDOM(resultsElement)

  afterEach -> waitsFor -> completeSpy.callCount > 0

  it 'is associated with ColorSearch model', ->
    expect(resultsElement).toBeDefined()

  it 'starts the search', ->
    expect(search.search).toHaveBeenCalled()

  describe 'when matches are found', ->
    beforeEach -> waitsFor -> completeSpy.callCount > 0

    it 'groups results by files', ->
      fileResults = resultsElement.querySelectorAll('.list-nested-item')

      expect(fileResults.length).toEqual(8)

      expect(fileResults[0].querySelectorAll('li.list-item').length).toEqual(3)

    describe 'when a file item is clicked', ->
      [fileItem] = []
      beforeEach ->
        fileItem = resultsElement.querySelector('.list-nested-item > .list-item')
        click(fileItem)

      it 'collapses the file matches', ->
        expect(resultsElement.querySelector('.list-nested-item.collapsed')).toExist()

    describe 'when a matches item is clicked', ->
      [matchItem, spy] = []
      beforeEach ->
        spy = jasmine.createSpy('did-add-text-editor')

        atom.workspace.onDidAddTextEditor(spy)
        matchItem = resultsElement.querySelector('.search-result.list-item')
        click(matchItem)

        waitsFor -> spy.callCount > 0

      it 'opens the file', ->
        expect(spy).toHaveBeenCalled()
        {textEditor} = spy.argsForCall[0][0]
        expect(textEditor.getSelectedBufferRange()).toEqual([[1,13],[1,23]])
