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
          createVar 'bar', '0.5', [12,20], '/path/to/foo.styl', 2
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
        expect(arg.destroyed).toBeUndefined()
        expect(arg.updated).toBeUndefined()

      it 'stores the names of the variables', ->
        expect(collection.variableNames.sort()).toEqual(['foo','bar','baz','bat','bab'].sort())

      it 'builds a dependencies map', ->
        expect(collection.dependencyGraph).toEqual({
          foo: ['baz']
          bar: ['bat']
          bat: ['bab']
        })

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

            arg = changeSpy.mostRecentCall.args[0]
            expect(arg.created).toBeUndefined()
            expect(arg.destroyed).toBeUndefined()
            expect(arg.updated.length).toEqual(2)

        describe 'that is no longer a color', ->
          beforeEach ->
            collection.addMany([
              createVar 'foo', '20px', [0,10], '/path/to/foo.styl', 1
            ])

          it 'leaves the collection variables untouched', ->
            expect(collection.length).toEqual(5)

          it 'affects the colors variables within the collection', ->
            expect(collection.getColorVariables().length).toEqual(0)

          it 'updates the existing variable value', ->
            variable = collection.find({
              name: 'foo'
              path: '/path/to/foo.styl'
            })
            expect(variable.value).toEqual('20px')
            expect(variable.isColor).toBeFalsy()

          it 'updates the variables depending on the changed variable', ->
            variable = collection.find({
              name: 'baz'
              path: '/path/to/foo.styl'
            })
            expect(variable.isColor).toBeFalsy()

          it 'emits a change event', ->
            arg = changeSpy.mostRecentCall.args[0]
            expect(changeSpy.callCount).toEqual(2)

            expect(arg.created).toBeUndefined()
            expect(arg.destroyed).toBeUndefined()
            expect(arg.updated.length).toEqual(2)

        describe 'that breaks a dependency', ->
          beforeEach ->
            collection.addMany([
              createVar 'baz', '#abc', [22,30], '/path/to/foo.styl', 3
            ])

          it 'leaves the collection untouched', ->
            expect(collection.length).toEqual(5)
            expect(collection.getColorVariables().length).toEqual(2)

          it 'updates the existing variable value', ->
            variable = collection.find({
              name: 'baz'
              path: '/path/to/foo.styl'
            })
            expect(variable.value).toEqual('#abc')
            expect(variable.isColor).toBeTruthy()
            expect(variable.color).toBeColor('#abc')

          it 'updates the dependencies graph', ->
            expect(collection.dependencyGraph).toEqual({
              bar: ['bat']
              bat: ['bab']
            })

        describe 'that adds a dependency', ->
          beforeEach ->
            collection.addMany([
              createVar 'baz', 'transparentize(foo, bar)', [22,30], '/path/to/foo.styl', 3
            ])

          it 'leaves the collection untouched', ->
            expect(collection.length).toEqual(5)
            expect(collection.getColorVariables().length).toEqual(2)

          it 'updates the existing variable value', ->
            variable = collection.find({
              name: 'baz'
              path: '/path/to/foo.styl'
            })
            expect(variable.value).toEqual('transparentize(foo, bar)')
            expect(variable.isColor).toBeTruthy()
            expect(variable.color).toBeColor(255,255,255, 0.5)

          it 'updates the dependencies graph', ->
            expect(collection.dependencyGraph).toEqual({
              foo: ['baz']
              bar: ['bat', 'baz']
              bat: ['bab']
            })

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
