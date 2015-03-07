VariableScanner = require '../lib/variable-scanner'

describe 'VariableScanner', ->
  [scanner, editor, text, bufferColor] = []

  withTextEditor = (fixture, block) ->
    describe "with #{fixture} buffer", ->
      beforeEach ->
        waitsForPromise -> atom.workspace.open(fixture)
        runs ->
          editor = atom.workspace.getActiveTextEditor()
          text = editor.getText()

      afterEach -> editor = null

      do block

  withScannerForTextEditor = (fixture, block) ->
    withTextEditor fixture, ->
      beforeEach -> scanner = new VariableScanner

      afterEach -> scanner = null

      do block

  describe '::search', ->
    [result] = []

    withScannerForTextEditor 'four-variables.styl', ->
      beforeEach ->
        result = scanner.search(text)

      it 'returns the first match', ->
        expect(result).toBeDefined()

      describe 'the result object', ->
        it 'has a match string', ->
          expect(result.match).toEqual('color = #fff')

        it 'has a lastIndex property', ->
          expect(result.lastIndex).toEqual(12)

        it 'has a range property', ->
          expect(result.range).toEqual([0,12])

        it 'has a variable result', ->
          expect(result[0].name).toEqual('color')
          expect(result[0].value).toEqual('#fff')
          expect(result[0].range).toEqual([0,12])

      describe 'the second result object', ->
        beforeEach ->
          result = scanner.search(text, result.lastIndex)

        it 'has a match string', ->
          expect(result.match).toEqual('other-color = transparentize(color, 50%)')

        it 'has a lastIndex property', ->
          expect(result.lastIndex).toEqual(54)

        it 'has a range property', ->
          expect(result.range).toEqual([14,54])

        it 'has a variable result', ->
          expect(result[0].name).toEqual('other-color')
          expect(result[0].value).toEqual('transparentize(color, 50%)')
          expect(result[0].range).toEqual([14,54])

      describe 'successive searches', ->
        it 'returns a result for each match and then undefined', ->
          doSearch = ->
            result = scanner.search(text, result.lastIndex)

          expect(doSearch()).toBeDefined()
          expect(doSearch()).toBeDefined()
          expect(doSearch()).toBeDefined()
          expect(doSearch()).toBeUndefined()
