
fdescribe 'autocomplete provider', ->
  [completionDelay, editor, editorView, pigments, autocompleteMain, autocompleteManager, jasmineContent] = []

  beforeEach ->
    runs ->
      jasmineContent = document.body.querySelector('#jasmine-content')

      atom.config.set('pigments.autocompleteScopes', ['*'])

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
      spyOn(pigments, 'provide').andCallThrough()

    waitsForPromise ->
      atom.workspace.open('sample.styl').then (e) ->
        editor = e
        editorView = atom.views.getView(editor)

    waitsForPromise ->
      Promise.all [
        atom.packages.activatePackage('autocomplete-plus')
        atom.packages.activatePackage('pigments')
      ]

    waitsForPromise -> pigments.getProject().initialize()

    waitsFor ->
      autocompleteMain.autocompleteManager?.ready and
        pigments.provide.calls.length is 1 and
        autocompleteMain.consumeProvider.calls.length is 1

    runs ->
      autocompleteManager = autocompleteMain.autocompleteManager
      spyOn(autocompleteManager, 'findSuggestions').andCallThrough()
      spyOn(autocompleteManager, 'displaySuggestions').andCallThrough()

  describe 'writing the name of a color', ->
    it 'returns sugestions for the matching colors', ->
      runs ->
        expect(editorView.querySelector('.autocomplete-plus')).not.toExist()

        editor.moveToBottom()
        editor.insertText('b')
        editor.insertText('a')

        advanceClock(completionDelay)

      waitsFor ->
        autocompleteManager.displaySuggestions.calls.length is 1

      runs ->
        expect(editorView.querySelector('.autocomplete-plus')).toExist()
        expect(editorView.querySelector('.autocomplete-plus span.word').textContent).toEqual('base-color')

        preview = editorView.querySelector('.autocomplete-plus span.completion-label .color-suggestion-preview')
        expect(preview).toExist()
        expect(preview.style.background).toEqual('rgb(255, 255, 255)')

  describe 'writing the name of a non-color variable', ->
    it 'returns sugestions for the matching variable', ->
      atom.config.set('pigments.extendAutocompleteToVariables', false)
      runs ->
        expect(editorView.querySelector('.autocomplete-plus')).not.toExist()

        editor.moveToBottom()
        editor.insertText('b')
        editor.insertText('u')
        editor.insertText('t')
        editor.insertText('p')

        advanceClock(completionDelay)

      waitsFor ->
        autocompleteManager.displaySuggestions.calls.length is 1

      runs ->
        expect(editorView.querySelector('.autocomplete-plus')).not.toExist()

  describe 'when extendAutocompleteToVariables is true', ->
    beforeEach ->
      atom.config.set('pigments.extendAutocompleteToVariables', true)

    describe 'writing the name of a non-color variable', ->
      it 'returns sugestions for the matching variable', ->
        runs ->
          expect(editorView.querySelector('.autocomplete-plus')).not.toExist()

          editor.moveToBottom()
          editor.insertText('b')
          editor.insertText('u')
          editor.insertText('t')
          editor.insertText('p')

          advanceClock(completionDelay)

        waitsFor ->
          autocompleteManager.displaySuggestions.calls.length is 1

        runs ->
          expect(editorView.querySelector('.autocomplete-plus')).toExist()
          expect(editorView.querySelector('.autocomplete-plus span.word').textContent).toEqual('button-padding')

          expect(editorView.querySelector('.autocomplete-plus span.completion-label').textContent).toEqual('6px 8px')
