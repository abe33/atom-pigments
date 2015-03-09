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
    {@ignores, @variables, @loadedPaths} = state
    @emitter = new Emitter

  onDidLoadPaths: (callback) ->
    @emitter.on 'did-load-paths', callback

  onDidLoadVariables: (callback) ->
    @emitter.on 'did-load-variables', callback

  onDidReloadFileVariables: (callback) ->
    @emitter.on 'did-reload-file-variables', callback

  loadPaths: ->
    return Promise.resolve(@loadedPaths) if @loadedPaths?

    new Promise (resolve, reject) =>
      PathLoader.startTask this, (results) =>
        @loadedPaths = results
        @emitter.emit 'did-load-paths', results
        resolve(results)

  resetPaths: ->
    delete @loadedPaths

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

    unless path in @loadedPaths
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

  getContext: ->
    new ColorContext(@variables)

  getColorVariables: ->
    context = @getContext()

    @variables.filter (variable) -> variable.isColor()

  getPalette: ->
    return new Palette unless @variables?

    colors = {}
    @getColorVariables().forEach (variable) -> colors[variable.name] = variable

    new Palette(colors)

  serialize: ->
    data = {deserializer: 'ColorProject'}

    data.ignores = @ignores if @ignores?
    data.loadedPaths = @loadedPaths if @loadedPaths?

    if @variables?
      data.variables = @variables.map (variable) -> variable.serialize()

    data
