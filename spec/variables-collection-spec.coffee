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

    ##       ###    ########  ########
    ##      ## ##   ##     ## ##     ##
    ##     ##   ##  ##     ## ##     ##
    ##    ##     ## ##     ## ##     ##
    ##    ######### ##     ## ##     ##
    ##    ##     ## ##     ## ##     ##
    ##    ##     ## ########  ########

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

        it 'does not trigger an update event', ->
          expect(changeSpy.callCount).toEqual(1)

      describe 'appending an already existing variable with a different value', ->
        describe 'that has a different range', ->
          beforeEach ->
            collection.addMany([
              createVar 'foo', '#aabbcc', [0,14], '/path/to/foo.styl', 1
            ])

          it 'leaves the collection untouched', ->
            expect(collection.length).toEqual(5)
            expect(collection.getColorVariables().length).toEqual(2)

          it 'updates the existing variable value', ->
            variable = collection.find({
              name: 'foo'
              path: '/path/to/foo.styl'
            })
            expect(variable.value).toEqual('#aabbcc')
            expect(variable.isColor).toBeTruthy()
            expect(variable.color).toBeColor('#aabbcc')

          it 'emits a change event', ->
            expect(changeSpy.callCount).toEqual(2)

            arg = changeSpy.mostRecentCall.args[0]
            expect(arg.created).toBeUndefined()
            expect(arg.destroyed).toBeUndefined()
            expect(arg.updated.length).toEqual(2)

        describe 'that has a different range and a different line', ->
          beforeEach ->
            collection.addMany([
              createVar 'foo', '#abc', [52,64], '/path/to/foo.styl', 6
            ])

          it 'appends the new variables', ->
            expect(collection.length).toEqual(6)
            expect(collection.getColorVariables().length).toEqual(3)

          it 'stores the two variables', ->
            variables = collection.findAll({
              name: 'foo'
              path: '/path/to/foo.styl'
            })
            expect(variables.length).toEqual(2)

          it 'emits a change event', ->
            expect(changeSpy.callCount).toEqual(2)

            arg = changeSpy.mostRecentCall.args[0]
            expect(arg.created.length).toEqual(1)
            expect(arg.destroyed).toBeUndefined()
            expect(arg.updated.length).toEqual(1)

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

    ##    ########  ######## ##     ##  #######  ##     ## ########
    ##    ##     ## ##       ###   ### ##     ## ##     ## ##
    ##    ##     ## ##       #### #### ##     ## ##     ## ##
    ##    ########  ######   ## ### ## ##     ## ##     ## ######
    ##    ##   ##   ##       ##     ## ##     ##  ##   ##  ##
    ##    ##    ##  ##       ##     ## ##     ##   ## ##   ##
    ##    ##     ## ######## ##     ##  #######     ###    ########

    describe '::removeMany', ->
      beforeEach ->
        collection.addMany([
          createVar 'foo', '#fff', [0,10], '/path/to/foo.styl', 1
          createVar 'bar', '0.5', [12,20], '/path/to/foo.styl', 2
          createVar 'baz', 'foo', [22,30], '/path/to/foo.styl', 3
          createVar 'bat', 'bar', [32,40], '/path/to/foo.styl', 4
          createVar 'bab', 'bat', [42,50], '/path/to/foo.styl', 5
        ])

      describe 'with variables that were not colors', ->
        beforeEach ->
          collection.removeMany([
            createVar 'bat', 'bar', [32,40], '/path/to/foo.styl', 4
            createVar 'bab', 'bat', [42,50], '/path/to/foo.styl', 5
          ])

        it 'removes the variables from the collection', ->
          expect(collection.length).toEqual(3)

        it 'dispatches a change event', ->
          expect(changeSpy).toHaveBeenCalled()

          arg = changeSpy.mostRecentCall.args[0]
          expect(arg.created).toBeUndefined()
          expect(arg.destroyed.length).toEqual(2)
          expect(arg.updated).toBeUndefined()

        it 'stores the names of the variables', ->
          expect(collection.variableNames.sort()).toEqual(['foo','bar','baz'].sort())

        it 'updates the variables per path map', ->
          expect(collection.variablesByPath['/path/to/foo.styl'].length).toEqual(3)

        it 'updates the dependencies map', ->
          expect(collection.dependencyGraph).toEqual({
            foo: ['baz']
          })

      describe 'with variables that were referenced by a color variable', ->
        beforeEach ->
          collection.removeMany([
            createVar 'foo', '#fff', [0,10], '/path/to/foo.styl', 1
          ])

        it 'removes the variables from the collection', ->
          expect(collection.length).toEqual(4)
          expect(collection.getColorVariables().length).toEqual(0)

        it 'dispatches a change event', ->
          expect(changeSpy).toHaveBeenCalled()

          arg = changeSpy.mostRecentCall.args[0]
          expect(arg.created).toBeUndefined()
          expect(arg.destroyed.length).toEqual(1)
          expect(arg.updated.length).toEqual(1)

        it 'stores the names of the variables', ->
          expect(collection.variableNames.sort()).toEqual(['bar','baz','bat','bab'].sort())

        it 'updates the variables per path map', ->
          expect(collection.variablesByPath['/path/to/foo.styl'].length).toEqual(4)

        it 'updates the dependencies map', ->
          expect(collection.dependencyGraph).toEqual({
            bar: ['bat']
            bat: ['bab']
          })

    ##    ##     ## ########  ########     ###    ######## ########
    ##    ##     ## ##     ## ##     ##   ## ##      ##    ##
    ##    ##     ## ##     ## ##     ##  ##   ##     ##    ##
    ##    ##     ## ########  ##     ## ##     ##    ##    ######
    ##    ##     ## ##        ##     ## #########    ##    ##
    ##    ##     ## ##        ##     ## ##     ##    ##    ##
    ##     #######  ##        ########  ##     ##    ##    ########

    describe '::updatePathCollection', ->
      beforeEach ->
        collection.addMany([
          createVar 'foo', '#fff', [0,10], '/path/to/foo.styl', 1
          createVar 'bar', '0.5', [12,20], '/path/to/foo.styl', 2
          createVar 'baz', 'foo', [22,30], '/path/to/foo.styl', 3
          createVar 'bat', 'bar', [32,40], '/path/to/foo.styl', 4
          createVar 'bab', 'bat', [42,50], '/path/to/foo.styl', 5
        ])

      describe 'when a new variable is added', ->
        beforeEach ->
          collection.updatePathCollection('/path/to/foo.styl' ,[
            createVar 'foo', '#fff', [0,10], '/path/to/foo.styl', 1
            createVar 'bar', '0.5', [12,20], '/path/to/foo.styl', 2
            createVar 'baz', 'foo', [22,30], '/path/to/foo.styl', 3
            createVar 'bat', 'bar', [32,40], '/path/to/foo.styl', 4
            createVar 'bab', 'bat', [42,50], '/path/to/foo.styl', 5
            createVar 'baa', '#f00', [52,60], '/path/to/foo.styl', 6
          ])

        it 'detects the addition and leave the rest of the collection unchanged', ->
          expect(collection.length).toEqual(6)
          expect(collection.getColorVariables().length).toEqual(3)
          expect(changeSpy.mostRecentCall.args[0].created.length).toEqual(1)
          expect(changeSpy.mostRecentCall.args[0].destroyed).toBeUndefined()
          expect(changeSpy.mostRecentCall.args[0].updated).toBeUndefined()

      describe 'when a variable is removed', ->
        beforeEach ->
          collection.updatePathCollection('/path/to/foo.styl' ,[
            createVar 'foo', '#fff', [0,10], '/path/to/foo.styl', 1
            createVar 'bar', '0.5', [12,20], '/path/to/foo.styl', 2
            createVar 'baz', 'foo', [22,30], '/path/to/foo.styl', 3
            createVar 'bat', 'bar', [32,40], '/path/to/foo.styl', 4
          ])

        it 'removes the variable that is not present in the new array', ->
          expect(collection.length).toEqual(4)
          expect(collection.getColorVariables().length).toEqual(2)
          expect(changeSpy.mostRecentCall.args[0].destroyed.length).toEqual(1)
          expect(changeSpy.mostRecentCall.args[0].created).toBeUndefined()
          expect(changeSpy.mostRecentCall.args[0].updated).toBeUndefined()


      describe 'when a new variable is changed', ->
        beforeEach ->
          collection.updatePathCollection('/path/to/foo.styl' ,[
            createVar 'foo', '#fff', [0,10], '/path/to/foo.styl', 1
            createVar 'bar', '0.5', [12,20], '/path/to/foo.styl', 2
            createVar 'baz', 'foo', [22,30], '/path/to/foo.styl', 3
            createVar 'bat', '#abc', [32,40], '/path/to/foo.styl', 4
            createVar 'bab', 'bat', [42,50], '/path/to/foo.styl', 5
          ])

        it 'detects the update', ->
          expect(collection.length).toEqual(5)
          expect(collection.getColorVariables().length).toEqual(4)
          expect(changeSpy.mostRecentCall.args[0].updated.length).toEqual(2)
          expect(changeSpy.mostRecentCall.args[0].destroyed).toBeUndefined()
          expect(changeSpy.mostRecentCall.args[0].created).toBeUndefined()

    ##    ########  ########  ######  ########  #######  ########  ########
    ##    ##     ## ##       ##    ##    ##    ##     ## ##     ## ##
    ##    ##     ## ##       ##          ##    ##     ## ##     ## ##
    ##    ########  ######    ######     ##    ##     ## ########  ######
    ##    ##   ##   ##             ##    ##    ##     ## ##   ##   ##
    ##    ##    ##  ##       ##    ##    ##    ##     ## ##    ##  ##
    ##    ##     ## ########  ######     ##     #######  ##     ## ########

    describe '::serialize', ->
      describe 'with an empty collection', ->
        it 'returns an empty serialized collection', ->
          expect(collection.serialize()).toEqual({
            deserializer: 'VariablesCollection'
            content: []
          })

      describe 'with a collection that contains a non-color variable', ->
        beforeEach ->
          collection.add createVar 'bar', '0.5', [12,20], '/path/to/foo.styl', 2

        it 'returns the serialized collection', ->
          expect(collection.serialize()).toEqual({
            deserializer: 'VariablesCollection'
            content: [
              {
                name: 'bar'
                value: '0.5'
                range: [12,20]
                path: '/path/to/foo.styl'
                line: 2
              }
            ]
          })

      describe 'with a collection that contains a color variable', ->
        beforeEach ->
          collection.add createVar 'bar', '#abc', [12,20], '/path/to/foo.styl', 2

        it 'returns the serialized collection', ->
          expect(collection.serialize()).toEqual({
            deserializer: 'VariablesCollection'
            content: [
              {
                name: 'bar'
                value: '#abc'
                range: [12,20]
                path: '/path/to/foo.styl'
                line: 2
                isColor: true
                color: [170, 187, 204, 1]
                variables: []
              }
            ]
          })

      describe 'with a collection that contains color variables with references', ->
        beforeEach ->
          collection.add createVar 'foo', '#abc', [0,10], '/path/to/foo.styl', 1
          collection.add createVar 'bar', 'foo', [12,20], '/path/to/foo.styl', 2

        it 'returns the serialized collection', ->
          expect(collection.serialize()).toEqual({
            deserializer: 'VariablesCollection'
            content: [
              {
                name: 'foo'
                value: '#abc'
                range: [0,10]
                path: '/path/to/foo.styl'
                line: 1
                isColor: true
                color: [170, 187, 204, 1]
                variables: []
              },
              {
                name: 'bar'
                value: 'foo'
                range: [12,20]
                path: '/path/to/foo.styl'
                line: 2
                isColor: true
                color: [170, 187, 204, 1]
                variables: ['foo']
              }
            ]
          })

    describe '.deserialize', ->
      beforeEach ->
        collection = atom.deserializers.deserialize({
          deserializer: 'VariablesCollection'
          content: [
            {
              name: 'foo'
              value: '#abc'
              range: [0,10]
              path: '/path/to/foo.styl'
              line: 1
              isColor: true
              color: [170, 187, 204, 1]
              variables: []
            },
            {
              name: 'bar'
              value: 'foo'
              range: [12,20]
              path: '/path/to/foo.styl'
              line: 2
              isColor: true
              color: [170, 187, 204, 1]
              variables: ['foo']
            },
            {
              name: 'baz'
              value: '0.5'
              range: [22,30]
              path: '/path/to/foo.styl'
              line: 3
            }
          ]
        })

      it 'restores the variables', ->
        expect(collection.length).toEqual(3)
        expect(collection.getColorVariables().length).toEqual(2)

      it 'restores all the denormalized data in the collection', ->
        expect(collection.variableNames).toEqual(['foo', 'bar', 'baz'])
        expect(Object.keys collection.variablesByPath).toEqual(['/path/to/foo.styl'])
        expect(collection.variablesByPath['/path/to/foo.styl'].length).toEqual(3)
        expect(collection.dependencyGraph).toEqual({
          foo: ['bar']
        })
