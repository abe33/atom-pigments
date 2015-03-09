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
    new Promise (resolve, reject) =>
      @loadPaths().then (paths) =>
        @scanPathsForVariables paths, (results) =>
          @variables = results.map(@createProjectVariable)
          @emitter.emit 'did-load-variables', @variables.slice()
          resolve(results)

  getVariablesForFile: (path) ->
    return undefined unless @variables?

    @variables.filter (variable) ->
      variable.relativePath is path or variable.path is path

  deleteVariablesForFile: (path) ->
    return unless @variables?

    @variables = @variables.filter (variable) -> variable.path isnt path

  reloadVariablesForFile: (path) ->
    unless @variables?
      return Promise.reject("Can't reload a path that haven't been loaded yet")

    unless path in @paths
      return Promise.reject("Can't reload a path that is not legible")

    @deleteVariablesForFile(path)
    @loadVariablesForFile(path).then (results) =>
      @emitter.emit 'did-reload-file-variables', {path, variables: results}

  loadVariablesForFile: (path) ->
    new Promise (resolve, reject) =>
      @scanPathsForVariables [path], (results) =>
        fileVariables = results.map(@createProjectVariable)
        @variables = @variables.concat(fileVariables)

        resolve(fileVariables)

  scanPathsForVariables: (paths, callback) ->
    PathsScanner.startTask paths, (results) ->
      callback(results)

  createProjectVariable: (result) => new ProjectVariable(result, this)

  serialize: ->
    data = {deserializer: 'ColorProject'}

    data.ignores = @ignores if @ignores?

    data.paths = @paths if @paths?

    if @variables?
      data.variables = @variables.map (variable) -> variable.serialize()

    data
