{Emitter} = require 'atom'
PathsLoader = require './paths-loader'
PathsScanner = require './paths-scanner'
ColorContext = require './color-context'
Palette = require './palette'
ProjectVariable = require './project-variable'

module.exports =
class ColorProject
  atom.deserializers.add(this)

  @deserialize: (state) -> new ColorProject(state)

  constructor: (state={}) ->
    {@ignores, @paths, variables, timestamp} = state
    @emitter = new Emitter

    @variables = variables.map(@createProjectVariable) if variables?
    @timestamp = new Date(Date.parse(timestamp)) if timestamp?

    @initialize() if @paths? and @variables?

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
        console.log @variables, paths
        @deleteVariablesForPaths(paths)
        console.log @variables
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

  resetPaths: ->
    delete @paths

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
    PathsScanner.startTask paths, (results) ->
      callback(results)

  createProjectVariable: (result) => new ProjectVariable(result, this)

  getTimestamp: -> new Date()

  serialize: ->
    data = {deserializer: 'ColorProject', timestamp: @getTimestamp()}

    data.ignores = @ignores if @ignores?

    if @isInitialized()
      data.paths = @paths
      data.variables = @variables.map (variable) -> variable.serialize()

    data
