{Emitter, CompositeDisposable} = require 'atom'
minimatch = require 'minimatch'

ColorBuffer = require './color-buffer'
ColorBufferElement = require './color-buffer-element'
ColorMarkerElement = require './color-marker-element'
ColorContext = require './color-context'
Palette = require './palette'
PathsLoader = require './paths-loader'
PathsScanner = require './paths-scanner'
ProjectVariable = require './project-variable'

ColorBufferElement.registerViewProvider(ColorBuffer)

module.exports =
class ColorProject
  atom.deserializers.add(this)

  @deserialize: (state) -> new ColorProject(state)

  constructor: (state={}) ->
    {@ignores, @paths, variables, timestamp, buffers} = state
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

    @bufferStates = buffers ? {}

    @timestamp = new Date(Date.parse(timestamp)) if timestamp?

    @initialize() if @paths? and @variables?
    @initializeBuffers()

  onDidInitialize: (callback) ->
    @emitter.on 'did-initialize', callback

  onDidUpdateVariables: (callback) ->
    @emitter.on 'did-update-variables', callback

  isInitialized: -> @initialized

  initialize: ->
    return Promise.resolve(@variables.slice()) if @isInitialized()
    return @initializePromise if @initializePromise?

    destroyed = null

    @initializePromise = @loadPaths()
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
      @variables = @variables.concat(results)

      if hadVariables
        @emitter.emit 'did-update-variables', {
          created: results
          destroyed: destroyed
        }

      results.forEach (variable) =>
        @createProjectVariableSubscriptions(variable)

      @initialized = true

      variables = @variables.slice()
      @emitter.emit 'did-initialize', variables
      variables

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
      atom.views.getView(buffer) if buffer?

  colorBufferForEditor: (editor) ->
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

  loadPaths: ->
    new Promise (resolve, reject) =>
      config = {
        @ignores
        @timestamp
        knownPaths: @paths
        paths: atom.project.getPaths()
      }
      PathsLoader.startTask config, (results) -> resolve(results)

  isIgnoredPath: (path) ->
    path = atom.project.relativize(path)
    ignores = atom.config.get('pigments.ignoredNames') ? []
    ignores = ignores.concat(@ignores) if @ignores?
    return true for ignore in ignores when minimatch(path, ignore)

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
    @getColorVariables().forEach (variable) -> colors[variable.name] = variable

    new Palette(colors)

  getContext: -> new ColorContext(@variables)

  getVariables: -> @variables?.slice()

  getVariableByName: (name) ->
    for variable in @variables
      return variable if variable.name is name

  getColorVariables: ->
    context = @getContext()

    @variables.filter (variable) -> variable.isColor()

  updateVariables: (paths, results) ->
    newVariables = @variables.filter (variable) -> variable.path not in paths
    toCreate = []
    for result in results
      if variable = @findVariable(result)
        # This is a special case, if both variables have a buffer range, they
        # can be equals and at the same time having a different text range.
        # In that case we always use the most recent range.
        if variable.range[0] isnt result.range[0] or variable.range[1] isnt result.range[1]
          variable.range = result.range
        newVariables.push(variable)
      else
        toCreate.push(result)

    newVariables = newVariables.concat(toCreate)

    toCreate.forEach (variable) => @createProjectVariableSubscriptions(variable)
    toDestroy = @variables.filter (variable) -> variable not in newVariables
    toDestroy.forEach (variable) =>
      @clearProjectVariableSubscriptions(variable)
      variable.destroy()

    if toDestroy.length > 0 or toCreate.length > 0
      @variables = newVariables
      @emitter.emit 'did-update-variables', {
        created: toCreate
        destroyed: toDestroy
      }

  findVariable: (result) ->
    return unless @variables?
    for variable in @variables
      return variable if variable.isEqual(result)

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
    data = {deserializer: 'ColorProject', timestamp: @getTimestamp()}

    data.ignores = @ignores if @ignores?
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
