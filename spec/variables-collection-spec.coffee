VariablesCollection = require '../lib/variables-collection'

describe 'VariablesCollection', ->
  [collection, changeSpy] = []

  createVar = (name, value, range, path, line) ->
    {name, value, range, path, line}

  describe 'with an empty collection', ->
    beforeEach ->
      collection = new VariablesCollection
      changeSpy = jasmine.createSpy('did-change')
      collection.onDidChange(changeSpy)

    describe '::addMany', ->
      beforeEach ->
        collection.addMany([
          createVar 'foo', '#fff', [0,10], '/path/to/foo.styl', 1
          createVar 'bar', '10px', [12,20], '/path/to/foo.styl', 2
          createVar 'baz', 'foo', [22,30], '/path/to/foo.styl', 3
          createVar 'bat', 'bar', [32,40], '/path/to/foo.styl', 4
          createVar 'bab', 'bat', [42,50], '/path/to/foo.styl', 5
        ])

      it 'stores them in the collection', ->
        expect(collection.length).toEqual(5)

      it 'detects that two of the variables are color variables', ->
        expect(collection.getColorVariables().length).toEqual(2)

      it 'dispatches a change event', ->
        expect(changeSpy).toHaveBeenCalled()
        arg = changeSpy.mostRecentCall.args[0]

        expect(arg.created.length).toEqual(5)
        expect(arg.destroyed.length).toEqual(0)
        expect(arg.updated.length).toEqual(0)

      describe 'appending an already existing variable', ->
        beforeEach ->
          collection.addMany([
            createVar 'foo', '#fff', [0,10], '/path/to/foo.styl', 1
          ])

        it 'leaves the collection untouched', ->
          expect(collection.length).toEqual(5)
          expect(collection.getColorVariables().length).toEqual(2)

      describe 'appending an already existing variable with a different value', ->
        describe 'that is still a color', ->
        beforeEach ->
          collection.addMany([
            createVar 'foo', '#abc', [0,10], '/path/to/foo.styl', 1
          ])

        it 'leaves the collection untouched', ->
          expect(collection.length).toEqual(5)
          expect(collection.getColorVariables().length).toEqual(2)

        it 'updates the existing variable value', ->
          variable = collection.find({
            name: 'foo'
            path: '/path/to/foo.styl'
          })
          expect(variable.value).toEqual('#abc')
          expect(variable.isColor).toBeTruthy()
          expect(variable.color).toBeColor('#abc')

        it 'emits a change event', ->
          expect(changeSpy.callCount).toEqual(2)

    describe '::removeMany', ->
      describe 'with variables that were not referenced by any other variables', ->
        beforeEach ->
          collection.removeMany([
            createVar 'bat', 'bar', [32,40], '/path/to/foo.styl', 4
            createVar 'bab', 'bat', [42,50], '/path/to/foo.styl', 5
          ])

      describe 'with variables that were referenced by other variables', ->
        beforeEach ->
          collection.removeMany([
            createVar 'foo', '#fff', [0,10], '/path/to/foo.styl', 1
            createVar 'bar', '10px', [12,20], '/path/to/foo.styl', 2
          ])
