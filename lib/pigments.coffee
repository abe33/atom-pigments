{CompositeDisposable} = require 'atom'
uris = require './uris'
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
      default: [
        "vendor/*",
        "node_modules/*",
        "spec/*",
        "test/*"
      ]
      description: "Glob patterns of files to ignore when scanning the project for variables."
      items:
        type: 'string'
    extendedSearchNames:
      type: 'array'
      default: [
        '**/*.css'
      ]
      description: "When performing the `find-colors` command, the search will scans all the files that match the `sourceNames` glob patterns and the one defined in this setting."
    ignoredScopes:
      type: 'array'
      default: []
      description: "Regular expressions of scopes in which colors are ignored. For example, to ignore all colors in comments you can use `\\.comment`."
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
      default: false
      description: 'When enabled, the autocomplete provider will also provides completion for non-color variables.'
    markerType:
      type: 'string'
      default: 'background'
      enum: ['background', 'outline', 'underline', 'dot', 'square-dot']
    sortPaletteColors:
      type: 'string'
      default: 'none'
      enum: ['none', 'by name', 'by color']
    groupPaletteColors:
      type: 'string'
      default: 'none'
      enum: ['none', 'by file']
    mergeColorDuplicates:
      type: 'boolean'
      default: false
    delayBeforeScan:
      type: 'integer'
      default: 500
      description: 'Number of milliseconds after which the current buffer will be scanned for changes in the colors. This delay starts at the end of the text input and will be aborted if you start typing again during the interval.'
    ignoreVcsIgnoredPaths:
      type: 'boolean'
      default: true
      title: 'Ignore VCS Ignored Paths'

  activate: (state) ->
    require './register-elements'

    @project = if state.project?
      atom.deserializers.deserialize(state.project)
    else
      new ColorProject()

    atom.commands.add 'atom-workspace',
      'pigments:find-colors': => @findColors()
      'pigments:show-palette': => @showPalette()
      'pigments:project-settings': => @showSettings()
      'pigments:reload': => @reloadProjectVariables()

    convertMethod = (action) => (event) =>
      marker = if @lastEvent?
        action @colorMarkerForMouseEvent(@lastEvent)
      else
        editor = atom.workspace.getActiveTextEditor()
        colorBuffer = @project.colorBufferForEditor(editor)

        editor.getCursors().forEach (cursor) =>
          marker = colorBuffer.getColorMarkerAtBufferPosition(cursor.getBufferPosition())
          action(marker)

      @lastEvent = null

    atom.commands.add 'atom-text-editor',
      'pigments:convert-to-hex': convertMethod (marker) ->
        marker.convertContentToHex() if marker?

      'pigments:convert-to-rgb': convertMethod (marker) ->
        marker.convertContentToRGB() if marker?

      'pigments:convert-to-rgba': convertMethod (marker) ->
        marker.convertContentToRGBA() if marker?

    atom.workspace.addOpener (uriToOpen) =>
      url ||= require 'url'

      {protocol, host} = url.parse uriToOpen
      return unless protocol is 'pigments:'

      switch host
        when 'search' then atom.views.getView(@project.findAllColors())
        when 'palette' then atom.views.getView(@project.getPalette())
        when 'settings' then atom.views.getView(@project)

    atom.contextMenu.add
      'atom-text-editor': [{
        label: 'Pigments'
        submenu: [
          {label: 'Convert to hexadecimal', command: 'pigments:convert-to-hex'}
          {label: 'Convert to RGB', command: 'pigments:convert-to-rgb'}
          {label: 'Convert to RGBA', command: 'pigments:convert-to-rgba'}
        ]
        shouldDisplay: (event) => @shouldDisplayContextMenu(event)
      }]

  deactivate: ->
    @getProject()?.destroy?()

  provideAutocomplete: ->
    PigmentsProvider ?= require './pigments-provider'
    new PigmentsProvider(this)

  provideAPI: ->
    PigmentsAPI ?= require './pigments-api'
    new PigmentsAPI(@getProject())

  shouldDisplayContextMenu: (event) ->
    @lastEvent = event
    setTimeout (=> @lastEvent = null), 10
    @colorMarkerForMouseEvent(event)?

  colorMarkerForMouseEvent: (event) ->
    editor = atom.workspace.getActiveTextEditor()
    colorBuffer = @project.colorBufferForEditor(editor)
    colorBuffer?.colorMarkerForMouseEvent(event)

  serialize: -> {project: @project.serialize()}

  getProject: -> @project

  findColors: ->
    pane = atom.workspace.paneForURI(uris.SEARCH)
    pane ||= atom.workspace.getActivePane()

    atom.workspace.openURIInPane(uris.SEARCH, pane, {})

  showPalette: ->
    @project.initialize().then ->
      pane = atom.workspace.paneForURI(uris.PALETTE)
      pane ||= atom.workspace.getActivePane()

      atom.workspace.openURIInPane(uris.PALETTE, pane, {})
    .catch (reason) ->
      console.error reason

  showSettings: ->
    @project.initialize().then ->
      pane = atom.workspace.paneForURI(uris.SETTINGS)
      pane ||= atom.workspace.getActivePane()

      atom.workspace.openURIInPane(uris.SETTINGS, pane, {})
    .catch (reason) ->
      console.error reason

  reloadProjectVariables: ->
    @project.initialize().then =>
      @project.loadPathsAndVariables()
    .catch (reason) ->
      console.error reason
