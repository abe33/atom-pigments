
describe 'autocomplete provider', ->
  [completionDelay, editor, editorView, pigments, autocompleteMain, autocompleteManager, jasmineContent, project] = []

  beforeEach ->
    runs ->
      jasmineContent = document.body.querySelector('#jasmine-content')

      atom.config.set('pigments.autocompleteScopes', ['*'])
      atom.config.set('pigments.sourceNames', [
        '**/*.styl'
        '**/*.less'
      ])

      # Set to live completion
      atom.config.set('autocomplete-plus.enableAutoActivation', true)
      # Set the completion delay
      completionDelay = 100
      atom.config.set('autocomplete-plus.autoActivationDelay', completionDelay)
      completionDelay += 100 # Rendering delay
      workspaceElement = atom.views.getView(atom.workspace)

      jasmineContent.appendChild(workspaceElement)

    waitsForPromise 'autocomplete-plus activation', ->
      atom.packages.activatePackage('autocomplete-plus').then (pkg) ->
        autocompleteMain = pkg.mainModule

    waitsForPromise 'pigments activation', ->
      atom.packages.activatePackage('pigments').then (pkg) ->
        pigments = pkg.mainModule

    runs ->
      spyOn(autocompleteMain, 'consumeProvider').andCallThrough()
      spyOn(pigments, 'provideAutocomplete').andCallThrough()

    waitsForPromise 'open sample file', ->
      atom.workspace.open('sample.styl').then (e) ->
        editor = e
        editor.setText ''
        editorView = atom.views.getView(editor)

    waitsForPromise 'pigments project initialized', ->
      project = pigments.getProject()
      project.initialize()

    runs ->
      autocompleteManager = autocompleteMain.autocompleteManager
      spyOn(autocompleteManager, 'findSuggestions').andCallThrough()
      spyOn(autocompleteManager, 'displaySuggestions').andCallThrough()

  describe 'writing the name of a color', ->
    it 'returns suggestions for the matching colors', ->
      runs ->
        expect(editorView.querySelector('.autocomplete-plus')).not.toExist()

        editor.moveToBottom()
        editor.insertText('border: 1px solid ')
        editor.moveToBottom()
        editor.insertText('b')
        editor.insertText('a')

        advanceClock(completionDelay)

      waitsFor ->
        autocompleteManager.displaySuggestions.calls.length is 1

      waitsFor -> editorView.querySelector('.autocomplete-plus li')?

      runs ->
        popup = editorView.querySelector('.autocomplete-plus')
        expect(popup).toExist()
        expect(popup.querySelector('span.word').textContent).toEqual('base-color')

        preview = popup.querySelector('.color-suggestion-preview')
        expect(preview).toExist()
        expect(preview.style.background).toEqual('rgb(255, 255, 255)')

    it 'replaces the prefix even when it contains a @', ->
      runs ->
        expect(editorView.querySelector('.autocomplete-plus')).not.toExist()

        editor.moveToBottom()
        editor.insertText('@')
        editor.insertText('b')
        editor.insertText('a')

        advanceClock(completionDelay)

      waitsFor ->
        autocompleteManager.displaySuggestions.calls.length is 1

      waitsFor -> editorView.querySelector('.autocomplete-plus li')?

      runs ->
        atom.commands.dispatch(editorView, 'autocomplete-plus:confirm')
        expect(editor.getText()).not.toContain '@@'

    it 'replaces the prefix even when it contains a $', ->
      runs ->
        expect(editorView.querySelector('.autocomplete-plus')).not.toExist()

        editor.moveToBottom()
        editor.insertText('$')
        editor.insertText('o')
        editor.insertText('t')

        advanceClock(completionDelay)

      waitsFor ->
        autocompleteManager.displaySuggestions.calls.length is 1

      waitsFor -> editorView.querySelector('.autocomplete-plus li')?

      runs ->
        atom.commands.dispatch(editorView, 'autocomplete-plus:confirm')
        expect(editor.getText()).toContain '$other-color'
        expect(editor.getText()).not.toContain '$$'

    describe 'when the extendAutocompleteToColorValue setting is enabled', ->
      beforeEach ->
        atom.config.set('pigments.extendAutocompleteToColorValue', true)

      describe 'with an opaque color', ->
        it 'displays the color hexadecimal code in the completion item', ->
          runs ->
            expect(editorView.querySelector('.autocomplete-plus')).not.toExist()

            editor.moveToBottom()
            editor.insertText('b')
            editor.insertText('a')
            editor.insertText('s')

            advanceClock(completionDelay)

          waitsFor ->
            autocompleteManager.displaySuggestions.calls.length is 1

          waitsFor ->
            editorView.querySelector('.autocomplete-plus li')?

          runs ->
            popup = editorView.querySelector('.autocomplete-plus')
            expect(popup).toExist()
            expect(popup.querySelector('span.word').textContent).toEqual('base-color')

            expect(popup.querySelector('span.right-label').textContent).toContain('#ffffff')

      describe 'when the autocompleteSuggestionsFromValue setting is enabled', ->
        beforeEach ->
          atom.config.set('pigments.autocompleteSuggestionsFromValue', true)

        it 'suggests color variables from hexadecimal values', ->
          runs ->
            expect(editorView.querySelector('.autocomplete-plus')).not.toExist()

            editor.moveToBottom()
            editor.insertText('#')
            editor.insertText('f')
            editor.insertText('f')

            advanceClock(completionDelay)

          waitsFor ->
            autocompleteManager.displaySuggestions.calls.length is 1

          waitsFor ->
            editorView.querySelector('.autocomplete-plus li')?

          runs ->
            popup = editorView.querySelector('.autocomplete-plus')
            expect(popup).toExist()
            expect(popup.querySelector('span.word').textContent).toEqual('var1')

            expect(popup.querySelector('span.right-label').textContent).toContain('#ffffff')

        it 'suggests color variables from hexadecimal values when in a CSS expression', ->
          runs ->
            expect(editorView.querySelector('.autocomplete-plus')).not.toExist()

            editor.moveToBottom()
            editor.insertText('border: 1px solid ')
            editor.moveToBottom()
            editor.insertText('#')
            editor.insertText('f')
            editor.insertText('f')

            advanceClock(completionDelay)

          waitsFor ->
            autocompleteManager.displaySuggestions.calls.length is 1

          waitsFor ->
            editorView.querySelector('.autocomplete-plus li')?

          runs ->
            popup = editorView.querySelector('.autocomplete-plus')
            expect(popup).toExist()
            expect(popup.querySelector('span.word').textContent).toEqual('var1')

            expect(popup.querySelector('span.right-label').textContent).toContain('#ffffff')

        it 'suggests color variables from rgb values', ->
          runs ->
            expect(editorView.querySelector('.autocomplete-plus')).not.toExist()

            editor.moveToBottom()
            editor.insertText('border: 1px solid ')
            editor.moveToBottom()
            editor.insertText('r')
            editor.insertText('g')
            editor.insertText('b')
            editor.insertText('(')
            editor.insertText('2')
            editor.insertText('5')
            editor.insertText('5')
            editor.insertText(',')
            editor.insertText(' ')

            advanceClock(completionDelay)

          waitsFor ->
            autocompleteManager.displaySuggestions.calls.length is 1

          waitsFor ->
            editorView.querySelector('.autocomplete-plus li')?

          runs ->
            popup = editorView.querySelector('.autocomplete-plus')
            expect(popup).toExist()
            expect(popup.querySelector('span.word').textContent).toEqual('var1')

            expect(popup.querySelector('span.right-label').textContent).toContain('#ffffff')

        describe 'and when extendAutocompleteToVariables is true', ->
          beforeEach ->
            atom.config.set('pigments.extendAutocompleteToVariables', true)

          it 'returns suggestions for the matching variable value', ->
            runs ->
              expect(editorView.querySelector('.autocomplete-plus')).not.toExist()

              editor.moveToBottom()
              editor.insertText('border: ')
              editor.moveToBottom()
              editor.insertText('6')
              editor.insertText('p')
              editor.insertText('x')
              editor.insertText(' ')

              advanceClock(completionDelay)

            waitsFor ->
              autocompleteManager.displaySuggestions.calls.length is 1

            waitsFor -> editorView.querySelector('.autocomplete-plus li')?

            runs ->
              popup = editorView.querySelector('.autocomplete-plus')
              expect(popup).toExist()
              expect(popup.querySelector('span.word').textContent).toEqual('button-padding')

              expect(popup.querySelector('span.right-label').textContent).toEqual('6px 8px')


      describe 'with a transparent color', ->
        it 'displays the color hexadecimal code in the completion item', ->
          runs ->
            expect(editorView.querySelector('.autocomplete-plus')).not.toExist()

            editor.moveToBottom()
            editor.insertText('$')
            editor.insertText('o')
            editor.insertText('t')

            advanceClock(completionDelay)

          waitsFor ->
            autocompleteManager.displaySuggestions.calls.length is 1

          waitsFor ->
            editorView.querySelector('.autocomplete-plus li')?

          runs ->
            popup = editorView.querySelector('.autocomplete-plus')
            expect(popup).toExist()
            expect(popup.querySelector('span.word').textContent).toEqual('$other-color')

            expect(popup.querySelector('span.right-label').textContent).toContain('rgba(255,0,0,0.5)')

  describe 'writing the name of a non-color variable', ->
    it 'returns suggestions for the matching variable', ->
      atom.config.set('pigments.extendAutocompleteToVariables', false)
      runs ->
        expect(editorView.querySelector('.autocomplete-plus')).not.toExist()

        editor.moveToBottom()
        editor.insertText('f')
        editor.insertText('o')
        editor.insertText('o')

        advanceClock(completionDelay)

      waitsFor ->
        autocompleteManager.displaySuggestions.calls.length is 1

      runs ->
        expect(editorView.querySelector('.autocomplete-plus')).not.toExist()

  describe 'when extendAutocompleteToVariables is true', ->
    beforeEach ->
      atom.config.set('pigments.extendAutocompleteToVariables', true)

    describe 'writing the name of a non-color variable', ->
      it 'returns suggestions for the matching variable', ->
        runs ->
          expect(editorView.querySelector('.autocomplete-plus')).not.toExist()

          editor.moveToBottom()
          editor.insertText('b')
          editor.insertText('u')
          editor.insertText('t')
          editor.insertText('t')
          editor.insertText('o')
          editor.insertText('n')
          editor.insertText('-')
          editor.insertText('p')

          advanceClock(completionDelay)

        waitsFor ->
          autocompleteManager.displaySuggestions.calls.length is 1

        waitsFor -> editorView.querySelector('.autocomplete-plus li')?

        runs ->
          popup = editorView.querySelector('.autocomplete-plus')
          expect(popup).toExist()
          expect(popup.querySelector('span.word').textContent).toEqual('button-padding')

          expect(popup.querySelector('span.right-label').textContent).toEqual('6px 8px')

describe 'autocomplete provider', ->
  [completionDelay, editor, editorView, pigments, autocompleteMain, autocompleteManager, jasmineContent, project] = []

  describe 'for sass files', ->
    beforeEach ->
      runs ->
        jasmineContent = document.body.querySelector('#jasmine-content')

        atom.config.set('pigments.autocompleteScopes', ['*'])
        atom.config.set('pigments.sourceNames', [
          '**/*.sass'
          '**/*.scss'
        ])

        # Set to live completion
        atom.config.set('autocomplete-plus.enableAutoActivation', true)
        # Set the completion delay
        completionDelay = 100
        atom.config.set('autocomplete-plus.autoActivationDelay', completionDelay)
        completionDelay += 100 # Rendering delay
        workspaceElement = atom.views.getView(atom.workspace)

        jasmineContent.appendChild(workspaceElement)

      waitsForPromise 'autocomplete-plus activation', ->
        atom.packages.activatePackage('autocomplete-plus').then (pkg) ->
          autocompleteMain = pkg.mainModule

      waitsForPromise 'pigments activation', ->
        atom.packages.activatePackage('pigments').then (pkg) ->
          pigments = pkg.mainModule

      runs ->
        spyOn(autocompleteMain, 'consumeProvider').andCallThrough()
        spyOn(pigments, 'provideAutocomplete').andCallThrough()

      waitsForPromise 'open sample file', ->
        atom.workspace.open('sample.styl').then (e) ->
          editor = e
          editorView = atom.views.getView(editor)

      waitsForPromise 'pigments project initialized', ->
        project = pigments.getProject()
        project.initialize()

      runs ->
        autocompleteManager = autocompleteMain.autocompleteManager
        spyOn(autocompleteManager, 'findSuggestions').andCallThrough()
        spyOn(autocompleteManager, 'displaySuggestions').andCallThrough()

    it 'does not display the alternate sass version', ->
      runs ->
        expect(editorView.querySelector('.autocomplete-plus')).not.toExist()

        editor.moveToBottom()
        editor.insertText('$')
        editor.insertText('b')
        editor.insertText('a')

        advanceClock(completionDelay)

      waitsFor 'suggestions displayed callback', ->
        autocompleteManager.displaySuggestions.calls.length is 1

      waitsFor 'autocomplete lis', ->
        editorView.querySelector('.autocomplete-plus li')?

      runs ->
        lis = editorView.querySelectorAll('.autocomplete-plus li')
        hasAlternate = Array::some.call lis, (li) ->
          li.querySelector('span.word').textContent is '$base_color'

        expect(hasAlternate).toBeFalsy()
