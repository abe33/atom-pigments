{CompositeDisposable, Disposable} = require 'atom'
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
    ignoredBufferNames:
      type: 'array'
      default: []
      description: "Glob patterns of files that won't get any colors highlighted"
      items:
        type: 'string'
    extendedSearchNames:
      type: 'array'
      default: ['**/*.css']
      description: "When performing the `find-colors` command, the search will scans all the files that match the `sourceNames` glob patterns and the one defined in this setting."
    supportedFiletypes:
      type: 'array'
      default: ['*']
      description: "An array of file extensions where colors will be highlighted. If the wildcard `*` is present in this array then colors in every file will be highlighted."
    extendedFiletypesForColorWords:
      type: 'array'
      default: []
      description: "An array of file extensions where color values such as `red`, `azure` or `whitesmoke` will be highlighted. By default CSS and CSS pre-processors files are supported."
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
    extendAutocompleteToColorValue:
      type: 'boolean'
      default: false
      description: 'When enabled, the autocomplete provider will also provides color value.'
    markerType:
      type: 'string'
      default: 'background'
      enum: ['background', 'outline', 'underline', 'dot', 'square-dot', 'gutter']
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
    @project = if state.project?
      atom.deserializers.deserialize(state.project)
    else
      new ColorProject()

    atom.commands.add 'atom-workspace',
      'pigments:find-colors': => @findColors()
      'pigments:show-palette': => @showPalette()
      'pigments:project-settings': => @showSettings()
      'pigments:reload': => @reloadProjectVariables()
      'pigments:report': => @createPigmentsReport()

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

      'pigments:convert-to-hsl': convertMethod (marker) ->
        marker.convertContentToHSL() if marker?

      'pigments:convert-to-hsla': convertMethod (marker) ->
        marker.convertContentToHSLA() if marker?

    atom.workspace.addOpener (uriToOpen) =>
      url ||= require 'url'

      {protocol, host} = url.parse uriToOpen
      return unless protocol is 'pigments:'

      switch host
        when 'search' then @project.findAllColors()
        when 'palette' then @project.getPalette()
        when 'settings' then atom.views.getView(@project)

    atom.contextMenu.add
      'atom-text-editor': [{
        label: 'Pigments'
        submenu: [
          {label: 'Convert to hexadecimal', command: 'pigments:convert-to-hex'}
          {label: 'Convert to RGB', command: 'pigments:convert-to-rgb'}
          {label: 'Convert to RGBA', command: 'pigments:convert-to-rgba'}
          {label: 'Convert to HSL', command: 'pigments:convert-to-hsl'}
          {label: 'Convert to HSLA', command: 'pigments:convert-to-hsla'}
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

  consumeColorPicker: (api) ->
    @getProject().setColorPickerAPI(api)

    new Disposable =>
      @getProject().setColorPickerAPI(null)

  consumeColorExpressions: (options={}) ->
    registry = @getProject().getColorExpressionsRegistry()

    if options.expressions?
      names = options.expressions.map (e) -> e.name
      registry.createExpressions(options.expressions)

      new Disposable -> registry.removeExpression(name) for name in names
    else
      {name, regexpString, handle, scopes, priority} = options
      registry.createExpression(name, regexpString, priority, scopes, handle)

      new Disposable -> registry.removeExpression(name)

  consumeVariableExpressions: (options={}) ->
    registry = @getProject().getVariableExpressionsRegistry()

    if options.expressions?
      names = options.expressions.map (e) -> e.name
      registry.createExpressions(options.expressions)

      new Disposable -> registry.removeExpression(name) for name in names
    else
      {name, regexpString, handle, scopes, priority} = options
      registry.createExpression(name, regexpString, priority, scopes, handle)

      new Disposable -> registry.removeExpression(name)

  shouldDisplayContextMenu: (event) ->
    @lastEvent = event
    setTimeout (=> @lastEvent = null), 10
    @colorMarkerForMouseEvent(event)?

  colorMarkerForMouseEvent: (event) ->
    editor = atom.workspace.getActiveTextEditor()
    colorBuffer = @project.colorBufferForEditor(editor)
    colorBufferElement = atom.views.getView(colorBuffer)
    colorBufferElement?.colorMarkerForMouseEvent(event)

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

  createPigmentsReport: ->
    atom.workspace.open('pigments-report.json').then (editor) =>
      editor.setText(@createReport())

  createReport: ->
    o =
      atom: atom.getVersion()
      pigments: atom.packages.getLoadedPackage('pigments').metadata.version
      platform: require('os').platform()
      config: atom.config.get('pigments')
      project:
        config:
          sourceNames: @project.sourceNames
          searchNames: @project.searchNames
          ignoredNames: @project.ignoredNames
          ignoredScopes: @project.ignoredScopes
          includeThemes: @project.includeThemes
          ignoreGlobalSourceNames: @project.ignoreGlobalSourceNames
          ignoreGlobalSearchNames: @project.ignoreGlobalSearchNames
          ignoreGlobalIgnoredNames: @project.ignoreGlobalIgnoredNames
          ignoreGlobalIgnoredScopes: @project.ignoreGlobalIgnoredScopes
        paths: @project.getPaths()
        variables:
          colors: @project.getColorVariables().length
          total: @project.getVariables().length

    JSON.stringify(o, null, 2)
    .replace(///#{atom.project.getPaths().join('|')}///g, '<root>')

  loadDeserializersAndRegisterViews: ->
    ColorBuffer = require './color-buffer'
    ColorSearch = require './color-search'
    Palette = require './palette'
    ColorBufferElement = require './color-buffer-element'
    ColorMarkerElement = require './color-marker-element'
    ColorResultsElement = require './color-results-element'
    ColorProjectElement = require './color-project-element'
    PaletteElement = require './palette-element'
    VariablesCollection = require './variables-collection'

    ColorBufferElement.registerViewProvider(ColorBuffer)
    ColorResultsElement.registerViewProvider(ColorSearch)
    ColorProjectElement.registerViewProvider(ColorProject)
    PaletteElement.registerViewProvider(Palette)

    atom.deserializers.add(Palette)
    atom.deserializers.add(ColorSearch)
    atom.deserializers.add(ColorProject)
    atom.deserializers.add(ColorProjectElement)
    atom.deserializers.add(VariablesCollection)

module.exports.loadDeserializersAndRegisterViews()
