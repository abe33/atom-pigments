Color = require '../lib/color'
Palette = require '../lib/palette'

describe 'PaletteElement', ->
  [palette, paletteElement] = []

  describe 'as a view provider', ->
    beforeEach ->
      palette = new Palette
        red: new Color '#ff0000'
        green: new Color '#00ff00'
        blue: new Color '#0000ff'
        redCopy: new Color '#ff0000'

      paletteElement = atom.views.getView(palette)

    it 'is associated with the Palette model', ->
      expect(paletteElement).toBeDefined()

  describe 'when pigments:show-palette commands is triggered', ->
    [workspaceElement, pigments, project] = []
    beforeEach ->
      workspaceElement = atom.views.getView(atom.workspace)

      waitsForPromise -> atom.packages.activatePackage('pigments').then (pkg) ->
        pigments = pkg.mainModule
        project = pigments.getProject()

      waitsForPromise -> project.initialize()

      runs ->
        atom.commands.dispatch(workspaceElement, 'pigments:show-palette')

      waitsFor ->
        paletteElement = workspaceElement.querySelector('pigments-palette')

      runs ->
        palette = paletteElement.getModel()

    it 'opens a palette element', ->
      expect(paletteElement).toBeDefined()

    it 'creates as many list item as there is colors in the project', ->
      expect(paletteElement.querySelectorAll('li').length).not.toEqual(0)
      expect(paletteElement.querySelectorAll('li').length).toEqual(palette.tuple().length)
