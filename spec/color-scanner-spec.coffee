ColorScanner = require '../lib/color-scanner'
{TextEditor} = require 'atom'

describe 'ColorScanner', ->
  [scanner, editor, bufferColor] = []

  withTextEditor = (fixture, block) ->
    describe "with #{fixture} buffer", ->
      beforeEach ->
        waitsForPromise -> atom.workspace.open(fixture)
        runs -> editor = atom.workspace.getActiveTextEditor()

      afterEach -> editor = null

      do block

  withScannerForTextEditor = (fixture, block) ->
    withTextEditor fixture, ->
      beforeEach -> scanner = new ColorScanner(buffer: editor.getBuffer())

      afterEach -> scanner = null

      do block

  describe '::search', ->
    withScannerForTextEditor 'four-variables.styl', ->
      beforeEach ->
        bufferColor = scanner.search()

      it 'returns the first buffer color match', ->
        expect(bufferColor).toBeDefined()
