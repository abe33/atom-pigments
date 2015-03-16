{Emitter, CompositeDisposable} = require 'atom'
ColorBuffer = require './color-buffer'
ColorContext = require './color-context'
Palette = require './palette'
PathsLoader = require './paths-loader'
PathsScanner = require './paths-scanner'
ProjectVariable = require './project-variable'

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
    @timestamp = new Date(Date.parse(timestamp)) if timestamp?

    @initialize() if @paths? and @variables?
    @initializeBuffers(buffers)

  onDidInitialize: (callback) ->
    @emitter.on 'did-initialize', callback

  onDidUpdateVariables: (callback) ->
    @emitter.on 'did-update-variables', callback

  isInitialized: -> @initialized

  initialize: ->
    return Promise.resolve() if @isInitialized()
    return @initializePromise if @initializePromise?

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
      @deleteVariablesForPaths(paths)
      @loadVariablesForPaths(paths)
    .then (results) =>
      @variables ?= []
      @variables = @variables.concat(results)
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
      @colorBufferForEditor(editor)

  colorBufferForEditor: (editor) ->
    return unless editor?
    return @colorBuffersByEditorId[editor.id] if @colorBuffersByEditorId[editor.id]?

    @colorBuffersByEditorId[editor.id] = buffer = new ColorBuffer({editor, project: this})

    @subscriptions.add subscription = buffer.onDidDestroy =>
      @subscriptions.remove(subscription)
      subscription.dispose()
      delete @colorBuffersByEditorId[editor.id]

  colorBufferForPath: (path) ->
    for id,colorBuffer of @colorBuffersByEditorId
      return colorBuffer if colorBuffer.editor.getPath() is path

  ##    ##     ##    ###    ########   ######
  ##    ##     ##   ## ##   ##     ## ##    ##
  ##    ##     ##  ##   ##  ##     ## ##
  ##    ##     ## ##     ## ########   ######
  ##     ##   ##  ######### ##   ##         ##
  ##      ## ##   ##     ## ##    ##  ##    ##
  ##       ###    ##     ## ##     ##  ######

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

  getPalette: ->
    return new Palette unless @isInitialized()

    colors = {}
    @getColorVariables().forEach (variable) -> colors[variable.name] = variable

    new Palette(colors)

  getContext: -> new ColorContext(@variables)

  getVariables: -> @variables?.slice()

  getColorVariables: ->
    context = @getContext()

    @variables.filter (variable) -> variable.isColor()

  updateVariables: (paths, results) ->
    newVariables = @variables.filter (variable) -> variable.path not in paths
    toCreate = []
    for result in results
      if variable = @findVariable(result)
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

    @variables = @variables.filter (variable) ->
      if variable.path in paths
        variable.destroy()
        return false
      return true

  reloadVariablesForPath: (path) -> @reloadVariablesForPaths [path]

  reloadVariablesForPaths: (paths) ->
    unless @isInitialized()
      return Promise.reject("Can't reload paths that haven't been loaded yet")

    if paths.some((path) => path not in @paths)
      return Promise.reject("Can't reload paths that are not legible")

    @loadVariablesForPaths(paths).then (results) => @updateVariables(paths, results)

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
        @reloadVariablesForPath(variable.path)

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
