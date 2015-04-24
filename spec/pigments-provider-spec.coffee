
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

      autocompleteMain = atom.packages.loadPackage('autocomplete-plus').mainModule
      spyOn(autocompleteMain, 'consumeProvider').andCallThrough()
      pigments = atom.packages.loadPackage('pigments').mainModule
      spyOn(pigments, 'provideAutocomplete').andCallThrough()

    waitsForPromise ->
      atom.workspace.open('sample.styl').then (e) ->
        editor = e
        editorView = atom.views.getView(editor)

    waitsForPromise ->
      Promise.all [
        atom.packages.activatePackage('autocomplete-plus')
        atom.packages.activatePackage('pigments')
      ]

    waitsForPromise ->
      project = pigments.getProject()
      project.initialize()

    waitsFor ->
      autocompleteMain.autocompleteManager?.ready and
        pigments.provideAutocomplete.calls.length is 1 and
        autocompleteMain.consumeProvider.calls.length is 1

    runs ->
      autocompleteManager = autocompleteMain.autocompleteManager
      spyOn(autocompleteManager, 'findSuggestions').andCallThrough()
      spyOn(autocompleteManager, 'displaySuggestions').andCallThrough()

  describe 'writing the name of a color', ->
    it 'returns suggestions for the matching colors', ->
      runs ->
        expect(editorView.querySelector('.autocomplete-plus')).not.toExist()

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
