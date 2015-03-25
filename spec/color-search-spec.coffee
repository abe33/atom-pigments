require './spec-helper'
ColorSearch = require '../lib/color-search'

describe 'ColorSearch', ->
  [search, pigments, project] = []

  beforeEach ->
    waitsForPromise -> atom.packages.activatePackage('pigments').then (pkg) ->
      pigments = pkg.mainModule
      project = pigments.getProject()

    waitsForPromise -> project.initialize()

  describe 'when created with basic options', ->
    beforeEach ->
      search = new ColorSearch
        sourceNames: [
          '**/*.styl'
          '**/*.less'
        ]
        ignoredNames: [
          'project/vendor/**'
        ]
        context: project.getContext()

    it 'dispatches a did-complete-search when finalizing its search', ->
      spy = jasmine.createSpy('did-complete-search')
      search.onDidCompleteSearch(spy)
      waitsFor -> spy.callCount > 0
      runs -> expect(spy.argsForCall[0][0].length).toEqual(23)
