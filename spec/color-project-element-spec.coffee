{change} = require './helpers/events'

describe 'ColorProjectElement', ->
  [pigments, project, projectElement] = []

  beforeEach ->
    jasmineContent = document.body.querySelector('#jasmine-content')

    waitsForPromise -> atom.packages.activatePackage('pigments').then (pkg) ->
      pigments = pkg.mainModule
      project = pigments.getProject()
      projectElement = atom.views.getView(project)
      jasmineContent.appendChild(projectElement)

  it 'is bound to the ColorProject model', ->
    expect(projectElement).toExist()

  describe 'typing in the sourceNames input', ->
    it 'update the source names in the project', ->
      spyOn(project, 'setSourceNames')

      projectElement.sourceNames.getModel().setText('foo, bar')
      projectElement.sourceNames.getModel().getBuffer().emitter.emit('did-stop-changing')

      expect(project.setSourceNames).toHaveBeenCalledWith(['foo','bar'])

  describe 'typing in the ignoredNames input', ->
    it 'update the source names in the project', ->
      spyOn(project, 'setIgnoredNames')

      projectElement.ignoredNames.getModel().setText('foo, bar')
      projectElement.ignoredNames.getModel().getBuffer().emitter.emit('did-stop-changing')

      expect(project.setIgnoredNames).toHaveBeenCalledWith(['foo','bar'])

  describe 'typing in the ignoredScopes input', ->
    it 'update the source names in the project', ->
      spyOn(project, 'setIgnoredScopes')

      projectElement.ignoredScopes.getModel().setText('foo, bar')
      projectElement.ignoredScopes.getModel().getBuffer().emitter.emit('did-stop-changing')

      expect(project.setIgnoredScopes).toHaveBeenCalledWith(['foo','bar'])

  describe 'toggling on the includeThemes checkbox', ->
    it 'update the source names in the project', ->
      spyOn(project, 'setIncludeThemes')

      projectElement.includeThemes.checked = true
      change(projectElement.includeThemes)

      expect(project.setIncludeThemes).toHaveBeenCalledWith(true)

      projectElement.includeThemes.checked = false
      change(projectElement.includeThemes)

      expect(project.setIncludeThemes).toHaveBeenCalledWith(false)
