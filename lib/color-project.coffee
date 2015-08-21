{Emitter, CompositeDisposable, Range} = require 'atom'
minimatch = require 'minimatch'

{SERIALIZE_VERSION, SERIALIZE_MARKERS_VERSION} = require './versions'
ColorBuffer = require './color-buffer'
ColorContext = require './color-context'
ColorSearch = require './color-search'
Palette = require './palette'
PathsLoader = require './paths-loader'
PathsScanner = require './paths-scanner'
ColorMarkerElement = require './color-marker-element'
VariablesCollection = require './variables-collection'

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
    {@ignoredNames, @sourceNames, @ignoredScopes, @paths, variables, timestamp, buffers} = state
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

    @subscriptions.add atom.config.observe 'pigments.markerType', (type) ->
      ColorMarkerElement.setMarkerType(type) if type?

    @subscriptions.add atom.config.observe 'pigments.sourcesWarningThreshold', (@sourcesWarningThreshold) =>

    @subscriptions.add atom.config.observe 'pigments.ignoreVcsIgnoredPaths', =>
      @loadPathsAndVariables()

    @bufferStates = buffers ? {}

    @timestamp = new Date(Date.parse(timestamp)) if timestamp?

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
      config = {
        @timestamp
        ignoredNames: @getIgnoredNames()
        knownPaths: if noKnownPaths then [] else @paths
        paths: atom.project.getPaths()
        traverseIntoSymlinkDirectories: atom.config.get 'pigments.traverseIntoSymlinkDirectories'
        sourceNames: @getSourceNames()
        ignoreVcsIgnores: atom.config.get('pigments.ignoreVcsIgnoredPaths')
      }
      PathsLoader.startTask config, (results) -> resolve(results)

  updatePaths: ->
    return Promise.resolve() unless @initialized

    @loadPaths().then ({dirtied, removed}) =>
      @deleteVariablesForPaths(removed)

      @paths = @paths.filter (p) -> p not in removed
      @paths.push(p) for p in dirtied when p not in @paths

      @reloadVariablesForPaths(dirtied)

  getSourceNames: ->
    sourceNames = @sourceNames ? []
    sourceNames = sourceNames.concat(atom.config.get('pigments.sourceNames') ? [])

  setSourceNames: (sourceNames) ->
    @sourceNames = sourceNames ? []

    return if not @initialized? and not @initializePromise?

    @initialize().then => @loadPathsAndVariables(true)

  getSearchNames: ->
    @getSourceNames().concat(atom.config.get 'pigments.extendedSearchNames')

  getIgnoredNames: ->
    ignoredNames = @ignoredNames ? []
    ignoredNames = ignoredNames.concat(@getGlobalIgnoredNames() ? [])
    ignoredNames = ignoredNames.concat(atom.config.get('core.ignoredNames') ? [])

  getGlobalIgnoredNames: ->
    atom.config.get('pigments.ignoredNames')?.map (p) ->
      if /\/\*$/.test(p) then p + '*' else p

  setIgnoredNames: (ignoredNames) ->
    @ignoredNames = ignoredNames ? []

    return if not @initialized? and not @initializePromise?

    @initialize().then =>
      dirtied = @paths.filter (p) => @isIgnoredPath(p)
      @deleteVariablesForPaths(dirtied)

      @paths = @paths.filter (p) => !@isIgnoredPath(p)
      @loadPathsAndVariables(true)

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

    colors = {}
    @getColorVariables().forEach (variable) ->
      colors[variable.name] = variable.color

    new Palette(colors)

  getContext: -> @variables.getContext()

  getVariables: -> @variables.getVariables()

  getVariableById: (id) -> @variables.getVariableById(id)

  getVariableByName: (name) -> @variables.getVariableByName(name)

  getColorVariables: -> @variables.getColorVariables()

  getIgnoredScopes: ->
    ignoredScopes = @ignoredScopes ? []
    ignoredScopes = ignoredScopes.concat(atom.config.get('pigments.ignoredScopes') ? [])

  setIgnoredScopes: (ignoredScopes=[]) ->
    @ignoredScopes = ignoredScopes

    @emitter.emit('did-change-ignored-scopes', @getIgnoredScopes())

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

  getTimestamp: -> new Date()

  serialize: ->
    data =
      deserializer: 'ColorProject'
      timestamp: @getTimestamp()
      version: SERIALIZE_VERSION
      markersVersion: SERIALIZE_MARKERS_VERSION
      globalSourceNames: atom.config.get('pigments.sourceNames')
      globalIgnoredNames: atom.config.get('pigments.ignoredNames')

    data.ignoredScopes = @ignoredScopes if @ignoredScopes?
    data.ignoredNames = @ignoredNames if @ignoredNames?
    data.sourceNames = @sourceNames if @sourceNames?
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
