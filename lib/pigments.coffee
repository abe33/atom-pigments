{CompositeDisposable} = require 'atom'
ColorProject = require './color-project'
[PigmentsProvider, PigmentsAPI, url] = []

module.exports =
  config:
    traverseIntoSymlinkDirectories:
      type: 'boolean'
      default: false
    sourceNames:
      type: 'array'
      default: [
        '**/*.styl'
        '**/*.stylus'
        '**/*.less'
        '**/*.sass'
        '**/*.scss'
      ]
      description: "Glob patterns of files to scan for variables."
      items:
        type: 'string'
    ignoredNames:
      type: 'array'
      default: []
      description: "Glob patterns of files to ignore when scanning the project for variables."
      items:
        type: 'string'
    ignoredScopes:
      type: 'array'
      default: []
      description: "Regular expressions of scopes in which colors are ignored. Note that regular expressions are strings."
      items:
        type: 'string'
    autocompleteScopes:
      type: 'array'
      default: [
        '.source.css'
        '.source.css.less'
        '.source.sass'
        '.source.css.scss'
        '.source.stylus'
      ]
      description: 'The autocomplete provider will only complete color names in editors whose scope is present in this list.'
      items:
        type: 'string'
    extendAutocompleteToVariables:
      type: 'boolean'
      default: true
      description: 'When enabled, the autocomplete provider will also provides completion for non-color variables.'
    markerType:
      type: 'string'
      default: 'background'
      enum: ['background', 'outline', 'underline', 'dot']
    sortPaletteColors:
      type: 'string'
      default: 'none'
      enum: ['none', 'by name', 'by color']
    gorupPaletteColors:
      type: 'string'
      default: 'none'
      enum: ['none', 'by file']
    mergeColorDuplicates:
      type: 'boolean'
      default: false

  activate: (state) ->
    require './register-elements'

    @project = if state.project?
      atom.deserializers.deserialize(state.project)
    else
      new ColorProject()

    atom.commands.add 'atom-workspace',
      'pigments:find-colors': => @findColors()
      'pigments:show-palette': => @showPalette()

    atom.workspace.addOpener (uriToOpen) =>
      url ||= require 'url'

      {protocol, host} = url.parse uriToOpen
      return unless protocol is 'pigments:' and host is 'search'

      atom.views.getView(@project.findAllColors())

    atom.workspace.addOpener (uriToOpen) =>
      url ||= require 'url'

      {protocol, host} = url.parse uriToOpen
      return unless protocol is 'pigments:' and host is 'palette'

      atom.views.getView(@project.getPalette())

  deactivate: ->
    @getProject()?.destroy?()

  provideAutocomplete: ->
    PigmentsProvider ?= require './pigments-provider'
    new PigmentsProvider(@getProject())

  provideAPI: ->
    PigmentsAPI ?= require './pigments-api'
    new PigmentsAPI(@getProject())

  serialize: -> {project: @project.serialize()}

  getProject: -> @project

  findColors: ->
    uri = "pigments://search"

    pane = atom.workspace.paneForURI(uri)
    pane ||= atom.workspace.getActivePane()

    atom.workspace.openURIInPane(uri, pane, {})

  showPalette: ->
    @project.initialize().then ->
      uri = "pigments://palette"

      pane = atom.workspace.paneForURI(uri)
      pane ||= atom.workspace.getActivePane()

      atom.workspace.openURIInPane(uri, pane, {})
