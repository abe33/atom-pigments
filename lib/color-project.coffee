{Emitter, CompositeDisposable, Range} = require 'atom'
minimatch = require 'minimatch'

{SERIALIZE_VERSION, SERIALIZE_MARKERS_VERSION} = require './versions'
{THEME_VARIABLES} = require './uris'
ColorBuffer = require './color-buffer'
ColorContext = require './color-context'
ColorSearch = require './color-search'
Palette = require './palette'
PathsLoader = require './paths-loader'
PathsScanner = require './paths-scanner'
ColorMarkerElement = require './color-marker-element'
VariablesCollection = require './variables-collection'

ATOM_VARIABLES = [
  'text-color'
  'text-color-subtle'
  'text-color-highlight'
  'text-color-selected'
  'text-color-info'
  'text-color-success'
  'text-color-warning'
  'text-color-error'
  'background-color-info'
  'background-color-success'
  'background-color-warning'
  'background-color-error'
  'background-color-highlight'
  'background-color-selected'
  'app-background-color'
  'base-background-color'
  'base-border-color'
  'pane-item-background-color'
  'pane-item-border-color'
  'input-background-color'
  'input-border-color'
  'tool-panel-background-color'
  'tool-panel-border-color'
  'inset-panel-background-color'
  'inset-panel-border-color'
  'panel-heading-background-color'
  'panel-heading-border-color'
  'overlay-background-color'
  'overlay-border-color'
  'button-background-color'
  'button-background-color-hover'
  'button-background-color-selected'
  'button-border-color'
  'tab-bar-background-color'
  'tab-bar-border-color'
  'tab-background-color'
  'tab-background-color-active'
  'tab-border-color'
  'tree-view-background-color'
  'tree-view-border-color'
  'ui-site-color-1'
  'ui-site-color-2'
  'ui-site-color-3'
  'ui-site-color-4'
  'ui-site-color-5'
  'syntax-text-color'
  'syntax-cursor-color'
  'syntax-selection-color'
  'syntax-background-color'
  'syntax-wrap-guide-color'
  'syntax-indent-guide-color'
  'syntax-invisible-character-color'
  'syntax-result-marker-color'
  'syntax-result-marker-color-selected'
  'syntax-gutter-text-color'
  'syntax-gutter-text-color-selected'
  'syntax-gutter-background-color'
  'syntax-gutter-background-color-selected'
  'syntax-color-renamed'
  'syntax-color-added'
  'syntax-color-modified'
  'syntax-color-removed'
]

compareArray = (a,b) ->
  return false if not a? or not b?
  return false unless a.length is b.length
  return false for v,i in a when v isnt b[i]
  return true

module.exports =
class ColorProject
  atom.deserializers.add(this)

  @deserialize: (state) ->
    markersVersion = SERIALIZE_MARKERS_VERSION
    if state?.version isnt SERIALIZE_VERSION
      state = {}

    if state?.markersVersion isnt markersVersion
      delete state.variables
      delete state.buffers

    if not compareArray(state.globalSourceNames, atom.config.get('pigments.sourceNames')) or not compareArray(state.globalIgnoredNames, atom.config.get('pigments.ignoredNames'))
      delete state.variables
      delete state.buffers
      delete state.paths

    new ColorProject(state)

  constructor: (state={}) ->
    {
      includeThemes, @ignoredNames, @sourceNames, @ignoredScopes, @paths, @searchNames, @ignoreGlobalSourceNames, @ignoreGlobalIgnoredNames, @ignoreGlobalIgnoredScopes, @ignoreGlobalSearchNames, @ignoreGlobalSupportedFiletypes, @supportedFiletypes, variables, timestamp, buffers
    } = state
    @emitter = new Emitter
    @subscriptions = new CompositeDisposable
    @colorBuffersByEditorId = {}

    if variables?
      @variables = atom.deserializers.deserialize(variables)
    else
      @variables = new VariablesCollection

    @subscriptions.add @variables.onDidChange (results) =>
      @emitVariablesChangeEvent(results)

    @subscriptions.add atom.config.observe 'pigments.sourceNames', =>
      @updatePaths()

    @subscriptions.add atom.config.observe 'pigments.ignoredNames', =>
      @updatePaths()

    @subscriptions.add atom.config.observe 'pigments.ignoredScopes', =>
      @emitter.emit('did-change-ignored-scopes', @getIgnoredScopes())

    @subscriptions.add atom.config.observe 'pigments.supportedFiletypes', =>
      @updateIgnoredFiletypes()
      @emitter.emit('did-change-ignored-scopes', @getIgnoredScopes())

    @subscriptions.add atom.config.observe 'pigments.markerType', (type) ->
      ColorMarkerElement.setMarkerType(type) if type?

    @subscriptions.add atom.config.observe 'pigments.ignoreVcsIgnoredPaths', =>
      @loadPathsAndVariables()

    @bufferStates = buffers ? {}

    @timestamp = new Date(Date.parse(timestamp)) if timestamp?

    @setIncludeThemes(includeThemes) if includeThemes
    @updateIgnoredFiletypes()

    @initialize() if @paths? and @variables.length?
    @initializeBuffers()

  onDidInitialize: (callback) ->
    @emitter.on 'did-initialize', callback

  onDidDestroy: (callback) ->
    @emitter.on 'did-destroy', callback

  onDidUpdateVariables: (callback) ->
    @emitter.on 'did-update-variables', callback

  onDidCreateColorBuffer: (callback) ->
    @emitter.on 'did-create-color-buffer', callback

  onDidChangeIgnoredScopes: (callback) ->
    @emitter.on 'did-change-ignored-scopes', callback

  observeColorBuffers: (callback) ->
    callback(colorBuffer) for id,colorBuffer of @colorBuffersByEditorId
    @onDidCreateColorBuffer(callback)

  isInitialized: -> @initialized

  isDestroyed: -> @destroyed

  initialize: ->
    return Promise.resolve(@variables.getVariables()) if @isInitialized()
    return @initializePromise if @initializePromise?

    @initializePromise = @loadPathsAndVariables().then =>
      @initialized = true

      variables = @variables.getVariables()
      @emitter.emit 'did-initialize', variables
      variables

  destroy: ->
    return if @destroyed
    @destroyed = true

    PathsScanner.terminateRunningTask()

    buffer.destroy() for id,buffer of @colorBuffersByEditorId
    @colorBuffersByEditorId = null

    @subscriptions.dispose()
    @subscriptions = null

    @emitter.emit 'did-destroy', this
    @emitter.dispose()

  loadPathsAndVariables: ->
    destroyed = null

    @loadPaths().then ({dirtied, removed}) =>
      # We can find removed files only when there's already paths from
      # a serialized state
      if removed.length > 0
        @paths = @paths.filter (p) -> p not in removed
        @deleteVariablesForPaths(removed)

      # There was serialized paths, and the initialization discovered
      # some new or dirty ones.
      if @paths? and dirtied.length > 0
        @paths.push path for path in dirtied when path not in @paths

        # There was also serialized variables, so we'll rescan only the
        # dirty paths
        if @variables.length
          dirtied
        # There was no variables, so it's probably because the markers
        # version changed, we'll rescan all the files
        else
          @paths
      # There was no serialized paths, so there's no variables neither
      else unless @paths?
        @paths = dirtied
      # Only the markers version changed, all the paths from the serialized
      # state will be rescanned
      else unless @variables.length
        @paths
      # Nothing changed, there's no dirty paths to rescan
      else
        []
    .then (paths) =>
      @loadVariablesForPaths(paths)
    .then (results) =>
      @variables.updateCollection(results) if results?

  findAllColors: ->
    patterns = @getSearchNames()
    new ColorSearch
      sourceNames: patterns
      ignoredNames: @getIgnoredNames()
      context: @getContext()

  ##    ########  ##     ## ######## ######## ######## ########   ######
  ##    ##     ## ##     ## ##       ##       ##       ##     ## ##    ##
  ##    ##     ## ##     ## ##       ##       ##       ##     ## ##
  ##    ########  ##     ## ######   ######   ######   ########   ######
  ##    ##     ## ##     ## ##       ##       ##       ##   ##         ##
  ##    ##     ## ##     ## ##       ##       ##       ##    ##  ##    ##
  ##    ########   #######  ##       ##       ######## ##     ##  ######

  initializeBuffers: (buffers) ->
    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      buffer = @colorBufferForEditor(editor)
      if buffer?
        bufferElement = atom.views.getView(buffer)
        bufferElement.attach()

  colorBufferForEditor: (editor) ->
    return if @destroyed
    return unless editor?
    if @colorBuffersByEditorId[editor.id]?
      return @colorBuffersByEditorId[editor.id]

    if @bufferStates[editor.id]?
      state = @bufferStates[editor.id]
      state.editor = editor
      state.project = this
      delete @bufferStates[editor.id]
    else
      state = {editor, project: this}

    @colorBuffersByEditorId[editor.id] = buffer = new ColorBuffer(state)

    @subscriptions.add subscription = buffer.onDidDestroy =>
      @subscriptions.remove(subscription)
      subscription.dispose()
      delete @colorBuffersByEditorId[editor.id]

    @emitter.emit 'did-create-color-buffer', buffer

    buffer

  colorBufferForPath: (path) ->
    for id,colorBuffer of @colorBuffersByEditorId
      return colorBuffer if colorBuffer.editor.getPath() is path

  ##    ########     ###    ######## ##     ##  ######
  ##    ##     ##   ## ##      ##    ##     ## ##    ##
  ##    ##     ##  ##   ##     ##    ##     ## ##
  ##    ########  ##     ##    ##    #########  ######
  ##    ##        #########    ##    ##     ##       ##
  ##    ##        ##     ##    ##    ##     ## ##    ##
  ##    ##        ##     ##    ##    ##     ##  ######

  getPaths: -> @paths?.slice()

  appendPath: (path) -> @paths.push(path) if path?

  loadPaths: (noKnownPaths=false) ->
    new Promise (resolve, reject) =>
      rootPaths = @getRootPaths()
      knownPaths = if noKnownPaths then [] else @paths ? []
      config = {
        knownPaths
        @timestamp
        ignoredNames: @getIgnoredNames()
        paths: rootPaths
        traverseIntoSymlinkDirectories: atom.config.get 'pigments.traverseIntoSymlinkDirectories'
        sourceNames: @getSourceNames()
        ignoreVcsIgnores: atom.config.get('pigments.ignoreVcsIgnoredPaths')
      }
      PathsLoader.startTask config, (results) =>
        for p in knownPaths
          isDescendentOfRootPaths = rootPaths.some (root) ->
            p.indexOf(root) is 0

          unless isDescendentOfRootPaths
            results.removed ?= []
            results.removed.push(p)

        resolve(results)

  updatePaths: ->
    return Promise.resolve() unless @initialized

    @loadPaths().then ({dirtied, removed}) =>
      @deleteVariablesForPaths(removed)

      @paths = @paths.filter (p) -> p not in removed
      @paths.push(p) for p in dirtied when p not in @paths

      @reloadVariablesForPaths(dirtied)

  isVariablesSourcePath: (path) ->
    return false unless path
    path = atom.project.relativize(path)
    sources = @getSourceNames()
    return true for source in sources when minimatch(path, source, matchBase: true, dot: true)

  isIgnoredPath: (path) ->
    return false unless path
    path = atom.project.relativize(path)
    ignoredNames = @getIgnoredNames()
    return true for ignore in ignoredNames when minimatch(path, ignore, matchBase: true, dot: true)

  ##    ##     ##    ###    ########   ######
  ##    ##     ##   ## ##   ##     ## ##    ##
  ##    ##     ##  ##   ##  ##     ## ##
  ##    ##     ## ##     ## ########   ######
  ##     ##   ##  ######### ##   ##         ##
  ##      ## ##   ##     ## ##    ##  ##    ##
  ##       ###    ##     ## ##     ##  ######

  getPalette: ->
    return new Palette unless @isInitialized()
    new Palette(@getColorVariables())

  getContext: -> @variables.getContext()

  getVariables: -> @variables.getVariables()

  getVariableById: (id) -> @variables.getVariableById(id)

  getVariableByName: (name) -> @variables.getVariableByName(name)

  getColorVariables: -> @variables.getColorVariables()

  showVariableInFile: (variable) ->
    atom.workspace.open(variable.path).then (editor) ->
      buffer = editor.getBuffer()

      bufferRange = Range.fromObject [
        buffer.positionForCharacterIndex(variable.range[0])
        buffer.positionForCharacterIndex(variable.range[1])
      ]

      editor.setSelectedBufferRange(bufferRange, autoscroll: true)

  emitVariablesChangeEvent: (results) ->
    @emitter.emit 'did-update-variables', results

  loadVariablesForPath: (path) -> @loadVariablesForPaths [path]

  loadVariablesForPaths: (paths) ->
    new Promise (resolve, reject) =>
      @scanPathsForVariables paths, (results) => resolve(results)

  getVariablesForPath: (path) -> @variables.getVariablesForPath(path)

  getVariablesForPaths: (paths) -> @variables.getVariablesForPaths(paths)

  deleteVariablesForPath: (path) -> @deleteVariablesForPaths [path]

  deleteVariablesForPaths: (paths) ->
    @variables.deleteVariablesForPaths(paths)

  reloadVariablesForPath: (path) -> @reloadVariablesForPaths [path]

  reloadVariablesForPaths: (paths) ->
    promise = Promise.resolve()
    promise = @initialize() unless @isInitialized()

    promise
    .then =>
      if paths.some((path) => path not in @paths)
        return Promise.resolve([])

      @loadVariablesForPaths(paths)
    .then (results) =>
      @variables.updateCollection(results, paths)

  scanPathsForVariables: (paths, callback) ->
    if paths.length is 1 and colorBuffer = @colorBufferForPath(paths[0])
      colorBuffer.scanBufferForVariables().then (results) -> callback(results)
    else
      PathsScanner.startTask paths, (results) -> callback(results)

  loadThemesVariables: ->
    iterator = 0
    variables = []
    html = ''
    ATOM_VARIABLES.forEach (v) -> html += "<div class='#{v}'>#{v}</div>"

    div = document.createElement('div')
    div.className = 'pigments-sampler'
    div.innerHTML = html
    document.body.appendChild(div)

    ATOM_VARIABLES.forEach (v,i) ->
      node = div.children[i]
      color = getComputedStyle(node).color
      end = iterator + v.length + color.length + 4

      variable =
        name: "@#{v}"
        line: i
        value: color
        range: [iterator,end]
        path: THEME_VARIABLES

      iterator = end
      variables.push(variable)

    document.body.removeChild(div)
    return variables

  ##     ######  ######## ######## ######## #### ##    ##  ######    ######
  ##    ##    ## ##          ##       ##     ##  ###   ## ##    ##  ##    ##
  ##    ##       ##          ##       ##     ##  ####  ## ##        ##
  ##     ######  ######      ##       ##     ##  ## ## ## ##   ####  ######
  ##          ## ##          ##       ##     ##  ##  #### ##    ##        ##
  ##    ##    ## ##          ##       ##     ##  ##   ### ##    ##  ##    ##
  ##     ######  ########    ##       ##    #### ##    ##  ######    ######

  getRootPaths: -> atom.project.getPaths()

  getSourceNames: ->
    names = ['.pigments']
    names = names.concat(@sourceNames ? [])
    unless @ignoreGlobalSourceNames
      names = names.concat(atom.config.get('pigments.sourceNames') ? [])
    names

  setSourceNames: (@sourceNames=[]) ->
    return if not @initialized? and not @initializePromise?

    @initialize().then => @loadPathsAndVariables(true)

  setIgnoreGlobalSourceNames: (@ignoreGlobalSourceNames) ->
    @updatePaths()

  getSearchNames: ->
    names = []
    names = names.concat(@sourceNames ? [])
    names = names.concat(@searchNames ? [])
    unless @ignoreGlobalSearchNames
      names = names.concat(atom.config.get('pigments.sourceNames') ? [])
      names = names.concat(atom.config.get('pigments.extendedSearchNames') ? [])
    names

  setSearchNames: (@searchNames=[]) ->

  setIgnoreGlobalSearchNames: (@ignoreGlobalSearchNames) ->

  getIgnoredNames: ->
    names = @ignoredNames ? []
    unless @ignoreGlobalIgnoredNames
      names = names.concat(@getGlobalIgnoredNames() ? [])
      names = names.concat(atom.config.get('core.ignoredNames') ? [])
    names

  getGlobalIgnoredNames: ->
    atom.config.get('pigments.ignoredNames')?.map (p) ->
      if /\/\*$/.test(p) then p + '*' else p

  setIgnoredNames: (@ignoredNames=[]) ->
    return if not @initialized? and not @initializePromise?

    @initialize().then =>
      dirtied = @paths.filter (p) => @isIgnoredPath(p)
      @deleteVariablesForPaths(dirtied)

      @paths = @paths.filter (p) => !@isIgnoredPath(p)
      @loadPathsAndVariables(true)

  setIgnoreGlobalIgnoredNames: (@ignoreGlobalIgnoredNames) ->
    @updatePaths()

  getIgnoredScopes: ->
    scopes = @ignoredScopes ? []
    unless @ignoreGlobalIgnoredScopes
      scopes = scopes.concat(atom.config.get('pigments.ignoredScopes') ? [])

    scopes = scopes.concat(@ignoredFiletypes)
    scopes

  setIgnoredScopes: (@ignoredScopes=[]) ->
    @emitter.emit('did-change-ignored-scopes', @getIgnoredScopes())

  setIgnoreGlobalIgnoredScopes: (@ignoreGlobalIgnoredScopes) ->
    @emitter.emit('did-change-ignored-scopes', @getIgnoredScopes())

  setSupportedFiletypes: (@supportedFiletypes=[]) ->
    @updateIgnoredFiletypes()
    @emitter.emit('did-change-ignored-scopes', @getIgnoredScopes())

  updateIgnoredFiletypes: ->
    @ignoredFiletypes = @getIgnoredFiletypes()

  getIgnoredFiletypes: ->
    filetypes = @supportedFiletypes ? []

    unless @ignoreGlobalSupportedFiletypes
      filetypes = filetypes.concat(atom.config.get('pigments.supportedFiletypes') ? [])

    filetypes = ['*'] if filetypes.length is 0

    return [] if filetypes.some (type) -> type is '*'

    scopes = filetypes.map (ext) ->
      atom.grammars.selectGrammar("file.#{ext}")?.scopeName.replace(/\./g, '\\.')
    .filter (scope) -> scope?

    ["^(?!\\.(#{scopes.join('|')}))"]

  setIgnoreGlobalSupportedFiletypes: (@ignoreGlobalSupportedFiletypes) ->
    @updateIgnoredFiletypes()
    @emitter.emit('did-change-ignored-scopes', @getIgnoredScopes())

  themesIncluded: -> @includeThemes

  setIncludeThemes: (includeThemes) ->
    return Promise.resolve() if includeThemes is @includeThemes

    @includeThemes = includeThemes
    if @includeThemes
      @themesSubscription = atom.themes.onDidChangeActiveThemes =>
        return unless @includeThemes

        variables = @loadThemesVariables()
        @variables.updatePathCollection(THEME_VARIABLES, variables)

      @subscriptions.add @themesSubscription
      @variables.addMany(@loadThemesVariables())
    else
      @subscriptions.remove @themesSubscription
      @variables.deleteVariablesForPaths([THEME_VARIABLES])
      @themesSubscription.dispose()

  getTimestamp: -> new Date()

  serialize: ->
    data =
      deserializer: 'ColorProject'
      timestamp: @getTimestamp()
      version: SERIALIZE_VERSION
      markersVersion: SERIALIZE_MARKERS_VERSION
      globalSourceNames: atom.config.get('pigments.sourceNames')
      globalIgnoredNames: atom.config.get('pigments.ignoredNames')

    if @ignoreGlobalSourceNames?
      data.ignoreGlobalSourceNames = @ignoreGlobalSourceNames
    if @ignoreGlobalSearchNames?
      data.ignoreGlobalSearchNames = @ignoreGlobalSearchNames
    if @ignoreGlobalIgnoredNames?
      data.ignoreGlobalIgnoredNames = @ignoreGlobalIgnoredNames
    if @ignoreGlobalIgnoredScopes?
      data.ignoreGlobalIgnoredScopes = @ignoreGlobalIgnoredScopes
    if @includeThemes?
      data.includeThemes = @includeThemes
    if @ignoredScopes?
      data.ignoredScopes = @ignoredScopes
    if @ignoredNames?
      data.ignoredNames = @ignoredNames
    if @sourceNames?
      data.sourceNames = @sourceNames
    if @searchNames?
      data.searchNames = @searchNames

    data.buffers = @serializeBuffers()

    if @isInitialized()
      data.paths = @paths
      data.variables = @variables.serialize()

    data

  serializeBuffers: ->
    out = {}
    for id,colorBuffer of @colorBuffersByEditorId
      out[id] = colorBuffer.serialize()
    out
