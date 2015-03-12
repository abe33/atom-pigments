{Emitter} = require 'atom'
PathLoader = require './path-loader'
PathsScanner = require './paths-scanner'
ColorContext = require './color-context'
Palette = require './palette'
ProjectVariable = require './project-variable'

module.exports =
class ColorProject
  atom.deserializers.add(this)

  @deserialize: (state) -> new ColorProject(state)

  constructor: (state={}) ->
    {@ignores, variables, @paths} = state
    @emitter = new Emitter

    @variables = variables.map(@createProjectVariable) if variables?

  onDidLoadPaths: (callback) ->
    @emitter.on 'did-load-paths', callback

  onDidLoadVariables: (callback) ->
    @emitter.on 'did-load-variables', callback

  onDidReloadFileVariables: (callback) ->
    @emitter.on 'did-reload-file-variables', callback


  getPaths: -> @paths?.slice()

  loadPaths: ->
    return Promise.resolve(@paths) if @paths?

    new Promise (resolve, reject) =>
      PathLoader.startTask this, (results) =>
        @paths = results
        @emitter.emit 'did-load-paths', results
        resolve(results)

  resetPaths: ->
    delete @paths


  getPalette: ->
    return new Palette unless @variables?

    colors = {}
    @getColorVariables().forEach (variable) -> colors[variable.name] = variable

    new Palette(colors)

  getContext: -> new ColorContext(@variables)

  getVariables: -> @variables?.slice()

  getColorVariables: ->
    context = @getContext()

    @variables.filter (variable) -> variable.isColor()

  loadVariables: ->
    @loadPaths().then (paths) =>
      @loadVariablesForFiles(paths)
    .then (results) =>
      @emitter.emit 'did-load-variables', @variables.slice()
      results

  loadVariablesForFile: (path) -> @loadVariablesForFiles [path]

  loadVariablesForFiles: (paths) ->
    new Promise (resolve, reject) =>
      @scanPathsForVariables paths, (results) =>
        @variables ?= []

        filesVariables = results.map(@createProjectVariable)
        @variables = @variables.concat(filesVariables)

        resolve(filesVariables)

  getVariablesForFile: (path) ->
    return undefined unless @variables?

    @variables.filter (variable) -> variable.path is path

  deleteVariablesForFile: (path) -> @deleteVariablesForFiles [path]

  deleteVariablesForFiles: (paths) ->
    return unless @variables?

    @variables = @variables.filter (variable) ->
      if variable.path in paths
        variable.destroy()
        return false
      return true

  reloadVariablesForFile: (path) -> @reloadVariablesForFiles [path]

  reloadVariablesForFiles: (paths) ->
    unless @variables?
      return Promise.reject("Can't reload paths that haven't been loaded yet")

    if paths.some((path) => path not in @paths)
      return Promise.reject("Can't reload paths that are not legible")

    @deleteVariablesForFiles(paths)
    @loadVariablesForFiles(paths).then (results) =>
      @emitter.emit 'did-reload-file-variables', {path, variables: results}

  scanPathsForVariables: (paths, callback) ->
    PathsScanner.startTask paths, (results) ->
      callback(results)

  createProjectVariable: (result) => new ProjectVariable(result, this)

  getTimestamp: -> new Date()

  serialize: ->
    data = {deserializer: 'ColorProject', timestamp: @getTimestamp()}

    data.ignores = @ignores if @ignores?

    data.paths = @paths if @paths?

    if @variables?
      data.variables = @variables.map (variable) -> variable.serialize()

    data
