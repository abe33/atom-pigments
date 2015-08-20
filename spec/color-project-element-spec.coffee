
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
