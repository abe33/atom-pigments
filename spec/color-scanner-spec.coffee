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

      describe 'the resulting buffer color', ->
        it 'has a text range', ->
          expect(bufferColor.textRange).toEqual([8,12])

        it 'has a buffer range', ->
          expect(bufferColor.bufferRange).toEqual([[0, 8],[0, 12]])

        it 'has a color', ->
          expect(bufferColor.color).toBeColor('#ffffff')

        it 'stores the matched text', ->
          expect(bufferColor.match).toEqual('#fff')

      describe 'successive searches', ->
        it 'returns a buffer color for each match and then undefined', ->
          expect(scanner.search()).toBeDefined()
          expect(scanner.search()).toBeDefined()
          # expect(scanner.search()).toBeDefined()
          expect(scanner.search()).toBeUndefined()
