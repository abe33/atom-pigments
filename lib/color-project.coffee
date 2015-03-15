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
    @colorBuffersByEditorId = {}

    @variables = variables.map(@createProjectVariable) if variables?
    @timestamp = new Date(Date.parse(timestamp)) if timestamp?

    @initialize() if @paths? and @variables?
    @initializeBuffers(buffers)

  onDidInitialize: (callback) ->
    @emitter.on 'did-initialize', callback

  onDidReloadFileVariables: (callback) ->
    @emitter.on 'did-reload-file-variables', callback

  isInitialized: -> @initialized

  initialize: ->
    return Promise.resolve() if @isInitialized()
    return @initializePromise if @initializePromise?

    @initializePromise = @loadPaths()
    .then (paths) =>
      if @paths? and paths.length > 0
        @deleteVariablesForPaths(paths)
        @paths.push path for path in paths when path not in @paths
        paths
      else unless @paths?
        @paths = paths
      else
        []
    .then (paths) =>
      @loadVariablesForPaths(paths)
    .then (results) =>
      @initialized = true
      @emitter.emit 'did-initialize', @variables.slice()
      results

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

  loadVariablesForPath: (path) -> @loadVariablesForPaths [path]

  loadVariablesForPaths: (paths) ->
    new Promise (resolve, reject) =>
      @scanPathsForVariables paths, (results) =>
        @variables ?= []

        filesVariables = results.map(@createProjectVariable)
        @variables = @variables.concat(filesVariables)

        resolve(filesVariables)

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

    @deleteVariablesForPaths(paths)
    @loadVariablesForPaths(paths).then (results) =>
      @emitter.emit 'did-reload-file-variables', {path, variables: results}

  scanPathsForVariables: (paths, callback) ->
    if paths.length is 1 and colorBuffer = @colorBufferForPath(paths[0])
      colorBuffer.scanBufferForVariables().then (results) -> callback(results)
    else
      PathsScanner.startTask paths, (results) -> callback(results)

  createProjectVariable: (result) => new ProjectVariable(result, this)

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
