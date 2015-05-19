{Emitter, CompositeDisposable, Range} = require 'atom'
minimatch = require 'minimatch'

ColorBuffer = require './color-buffer'
ColorContext = require './color-context'
ColorSearch = require './color-search'
Palette = require './palette'
PathsLoader = require './paths-loader'
PathsScanner = require './paths-scanner'
ProjectVariable = require './project-variable'
ColorMarkerElement = require './color-marker-element'
SourcesPopupElement = require './sources-popup-element'

SERIALIZE_VERSION = "1.0.1"

module.exports =
class ColorProject
  atom.deserializers.add(this)

  @deserialize: (state) ->
    state = {} if state?.version isnt SERIALIZE_VERSION
    new ColorProject(state)

  constructor: (state={}) ->
    {@ignoredNames, @paths, variables, timestamp, buffers} = state
    @emitter = new Emitter
    @subscriptions = new CompositeDisposable
    @variablesSubscriptionsById = {}
    @colorBuffersByEditorId = {}

    if variables?
      @variables = variables.map (v) =>
        variable = @createProjectVariable(v)
        @createProjectVariableSubscriptions(variable)
        variable

    @subscriptions.add atom.config.observe 'pigments.markerType', (type) ->
      ColorMarkerElement.setMarkerType(type) if type?

    @subscriptions.add atom.config.observe 'pigments.sourcesWarningThreshold', (@sourcesWarningThreshold) =>

    @bufferStates = buffers ? {}

    @timestamp = new Date(Date.parse(timestamp)) if timestamp?

    @initialize() if @paths? and @variables?
    @initializeBuffers()

  onDidInitialize: (callback) ->
    @emitter.on 'did-initialize', callback

  onDidUpdateVariables: (callback) ->
    @emitter.on 'did-update-variables', callback

  onDidCreateColorBuffer: (callback) ->
    @emitter.on 'did-create-color-buffer', callback

  observeColorBuffers: (callback) ->
    callback(colorBuffer) for id,colorBuffer of @colorBuffersByEditorId
    @onDidCreateColorBuffer(callback)

  isInitialized: -> @initialized

  isDestroyed: -> @destroyed

  initialize: ->
    return Promise.resolve(@variables.slice()) if @isInitialized()
    return @initializePromise if @initializePromise?

    @initializePromise = @loadPathsAndVariables().then =>
      @initialized = true

      variables = @variables.slice()
      @emitter.emit 'did-initialize', variables
      variables

  destroy: ->
    return if @destroyed

    @destroyed = true

    buffer.destroy() for id,buffer of @colorBuffersByEditorId

    @colorBuffersByEditorId = null

  loadPathsAndVariables: ->
    destroyed = null

    @loadPaths().then (paths) =>
      if paths.length >= @sourcesWarningThreshold
        @openSourcesPopup()
      else
        Promise.resolve(paths)
    .then (paths) =>
      if @paths? and paths.length > 0
        @paths.push path for path in paths when path not in @paths
        paths
      else unless @paths?
        @paths = paths
      else
        []
    .then (paths) =>
      destroyed = @deleteVariablesForPaths(paths)
      @loadVariablesForPaths(paths)
    .then (results) =>
      hadVariables = @variables?
      @variables ?= []

      for variable in results
        @variables.push(variable) unless @findVariable(variable)

      @emitVariablesChangeEvent(results, destroyed, [], true) if hadVariables

      results.forEach (variable) =>
        @createProjectVariableSubscriptions(variable)

  findAllColors: ->
    new ColorSearch
      sourceNames: atom.config.get 'pigments.sourceNames'
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
      }
      PathsLoader.startTask config, (results) -> resolve(results)

  getIgnoredNames: ->
    ignoredNames = @ignoredNames ? []
    ignoredNames = ignoredNames.concat(atom.config.get('pigments.ignoredNames') ? [])
    ignoredNames = ignoredNames.concat(atom.config.get('core.ignoredNames') ? [])

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
    sources = atom.config.get('pigments.sourceNames')
    return true for source in sources when minimatch(path, source, matchBase: true, dot: true)

  isIgnoredPath: (path) ->
    return false unless path
    path = atom.project.relativize(path)
    ignoredNames = atom.config.get('pigments.ignoredNames') ? []
    ignoredNames = ignoredNames.concat(@ignoredNames) if @ignoredNames?
    return true for ignore in ignoredNames when minimatch(path, ignore, matchBase: true, dot: true)

  openSourcesPopup: (paths) ->
    new Promise (resolve, reject) ->
      popup = new SourcesPopupElement
      popup.initialize({paths, resolve, reject})
      workspaceElement = atom.views.getView(atom.workspace)
      panelContainer = workspaceElement.querySelector('atom-panel-container.modal')

      panelContainer.appendChild(popup)

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

  getContext: -> new ColorContext(@variables)

  getVariables: -> @variables?.slice()

  getVariableById: (id) ->
    return undefined unless @variables?
    for variable in @variables
      return variable if variable.id is id

  getVariableByName: (name) ->
    return undefined unless @variables?
    for variable in @variables
      return variable if variable.name is name

  getColorVariables: ->
    return @colorVariablesCache if @colorVariablesCache?
    context = @getContext()

    @colorVariablesCache = @variables.filter (variable) -> variable.isColor()

  showVariableInFile: (variable) ->
    atom.workspace.open(variable.path).then (editor) ->
      buffer = editor.getBuffer()

      bufferRange = Range.fromObject [
        buffer.positionForCharacterIndex(variable.range[0])
        buffer.positionForCharacterIndex(variable.range[1])
      ]

      editor.setSelectedBufferRange(bufferRange, autoscroll: true)

  updateVariables: (paths, results) ->
    newVariables = @variables.filter (variable) -> variable.path not in paths
    created = []
    updated = []

    for result in results
      if variable = @findVariable(result)
        # This is a special case, if both variables have a buffer range, they
        # can be equals and at the same time having a different text range.
        # In that case we always use the most recent range.
        if variable.range[0] isnt result.range[0] or variable.range[1] isnt result.range[1]
          variable.range = result.range
        newVariables.push(variable)
      else if variable = @findVariableWithoutRange(result)
        # This is another special case, when typing in the buffer, the variable
        # range changed but the declaration didn't. We just need to update its
        # ranges and mark it as updated.
        variable.range = result.range
        variable.bufferRange = result.bufferRange

        newVariables.push(variable)
        updated.push(variable)
      else
        created.push(result)

    newVariables = newVariables.concat(created)

    created.forEach (variable) => @createProjectVariableSubscriptions(variable)
    destroyed = @variables.filter (variable) -> variable not in newVariables
    destroyed.forEach (variable) =>
      @clearProjectVariableSubscriptions(variable)
      variable.destroy()

    @variables = newVariables
    @emitVariablesChangeEvent(created, destroyed, updated)

  findVariable: (result) ->
    return unless @variables?
    for variable in @variables
      return variable if variable.isEqual(result)

  findVariableWithoutRange: (result) ->
    return unless @variables?
    for variable in @variables
      return variable if variable.isValueEqual(result)

  emitVariablesChangeEvent: (created, destroyed, updated, forceEvent=false) ->
    if forceEvent or destroyed.length or created.length or updated.length
      @emitter.emit 'did-update-variables', {created, destroyed, updated}
      @colorVariablesCache = undefined

  loadVariablesForPath: (path) -> @loadVariablesForPaths [path]

  loadVariablesForPaths: (paths) ->
    new Promise (resolve, reject) =>
      @scanPathsForVariables paths, (results) =>
        resolve(results.map(@createProjectVariable))

  getVariablesForPath: (path) -> @getVariablesForPaths [path]

  getVariablesForPaths: (paths) ->
    return unless @isInitialized()

    @variables.filter (variable) -> variable.path in paths

  deleteVariablesForPath: (path) -> @deleteVariablesForPaths [path]

  deleteVariablesForPaths: (paths) ->
    return unless @variables?

    destroyed = []

    @variables = @variables.filter (variable) =>
      if variable.path in paths
        @clearProjectVariableSubscriptions(variable)
        variable.destroy()
        destroyed.push variable
        return false
      return true

    @reloadVariablesForPaths(paths)

    destroyed

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
      @updateVariables(paths, results)

  scanPathsForVariables: (paths, callback) ->
    if paths.length is 1 and colorBuffer = @colorBufferForPath(paths[0])
      colorBuffer.scanBufferForVariables().then (results) -> callback(results)
    else
      PathsScanner.startTask paths, (results) -> callback(results)

  createProjectVariable: (result) => new ProjectVariable(result, this)

  removeProjectVariable: (variable) ->
    @variables = @variables.filter (v) -> v isnt variable
    @clearProjectVariableSubscriptions(variable)

  createProjectVariableSubscriptions: (variable) ->
    unless @variablesSubscriptionsById[variable.id]?
      @variablesSubscriptionsById[variable.id] = variable.onDidDestroy =>
        @removeProjectVariable(variable)
        @reloadVariablesForPath(variable.path) if @isInitialized()

  clearProjectVariableSubscriptions: (variable) ->
    @variablesSubscriptionsById[variable.id].dispose()
    delete @variablesSubscriptionsById[variable.id]

  getTimestamp: -> new Date()

  serialize: ->
    data =
      deserializer: 'ColorProject'
      timestamp: @getTimestamp()
      version: SERIALIZE_VERSION

    data.ignoredNames = @ignoredNames if @ignoredNames?
    data.buffers = @serializeBuffers()

    if @isInitialized()
      data.paths = @paths
      data.variables = @variables.map (variable) -> variable.serialize()

    data

  serializeBuffers: ->
    out = {}
    for id,colorBuffer of @colorBuffersByEditorId
      out[id] = colorBuffer.serialize()
    out
