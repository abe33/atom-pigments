path = require 'path'
VariableScanner = require '../lib/variable-scanner'
registry = require '../lib/variable-expressions'
scopeFromFileName = require '../lib/scope-from-file-name'

describe 'VariableScanner', ->
  [scanner, editor, text, scope] = []

  withTextEditor = (fixture, block) ->
    describe "with #{fixture} buffer", ->
      beforeEach ->
        waitsForPromise -> atom.workspace.open(fixture)
        runs ->
          editor = atom.workspace.getActiveTextEditor()
          text = editor.getText()
          scope = scopeFromFileName(editor.getPath())

      afterEach ->
        editor = null
        scope = null

      do block

  withScannerForTextEditor = (fixture, block) ->
    withTextEditor fixture, ->
      beforeEach -> scanner = new VariableScanner({registry, scope})

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
          expect(result.match).toEqual('base-color = #fff')

        it 'has a lastIndex property', ->
          expect(result.lastIndex).toEqual(17)

        it 'has a range property', ->
          expect(result.range).toEqual([0,17])

        it 'has a variable result', ->
          expect(result[0].name).toEqual('base-color')
          expect(result[0].value).toEqual('#fff')
          expect(result[0].range).toEqual([0,17])
          expect(result[0].line).toEqual(0)

      describe 'the second result object', ->
        beforeEach ->
          result = scanner.search(text, result.lastIndex)

        it 'has a match string', ->
          expect(result.match).toEqual('other-color = transparentize(base-color, 50%)')

        it 'has a lastIndex property', ->
          expect(result.lastIndex).toEqual(64)

        it 'has a range property', ->
          expect(result.range).toEqual([19,64])

        it 'has a variable result', ->
          expect(result[0].name).toEqual('other-color')
          expect(result[0].value).toEqual('transparentize(base-color, 50%)')
          expect(result[0].range).toEqual([19,64])
          expect(result[0].line).toEqual(2)

      describe 'successive searches', ->
        it 'returns a result for each match and then undefined', ->
          doSearch = ->
            result = scanner.search(text, result.lastIndex)

          expect(doSearch()).toBeDefined()
          expect(doSearch()).toBeDefined()
          expect(doSearch()).toBeDefined()
          expect(doSearch()).toBeUndefined()

    withScannerForTextEditor 'incomplete-stylus-hash.styl', ->
      beforeEach ->
        result = scanner.search(text)

      it 'does not find any variables', ->
        expect(result).toBeUndefined()

    withScannerForTextEditor 'variables-in-arguments.scss', ->
      beforeEach ->
        result = scanner.search(text)

      it 'does not find any variables', ->
        expect(result).toBeUndefined()

    withScannerForTextEditor 'attribute-selectors.scss', ->
      beforeEach ->
        result = scanner.search(text)

      it 'does not find any variables', ->
        expect(result).toBeUndefined()

    withScannerForTextEditor 'variables-in-conditions.scss', ->
      beforeEach ->
        result = null
        doSearch = -> result = scanner.search(text, result?.lastIndex)

        doSearch()
        doSearch()

      it 'does not find the variable in the if clause', ->
        expect(result).toBeUndefined()

    withScannerForTextEditor 'variables-after-mixins.scss', ->
      beforeEach ->
        result = null
        doSearch = -> result = scanner.search(text, result?.lastIndex)

        doSearch()

      it 'finds the variable after the mixin', ->
        expect(result).toBeDefined()

    withScannerForTextEditor 'variables-from-other-process.less', ->
      beforeEach ->
        result = null
        doSearch = -> result = scanner.search(text, result?.lastIndex)

        doSearch()

      it 'finds the variable with an interpolation tag', ->
        expect(result).toBeDefined()

    withScannerForTextEditor 'crlf.styl', ->
      beforeEach ->
        result = null
        doSearch = -> result = scanner.search(text, result?.lastIndex)

        doSearch()
        doSearch()

      it 'finds all the variables even with crlf mode', ->
        expect(result).toBeDefined()
