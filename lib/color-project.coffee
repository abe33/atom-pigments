PathLoader = require './path-loader'
PathsScanner = require './paths-scanner'
ColorContext = require './color-context'
Palette = require './palette'

module.exports =
class ColorProject
  atom.deserializers.add(this)

  @deserialize: (state) -> new ColorProject(state)

  constructor: (state={}) ->
    {@ignores, @variables, @loadedPaths} = state

  loadPaths: ->
    return Promise.resolve(@loadedPaths) if @loadedPaths?

    new Promise (resolve, reject) =>
      PathLoader.startTask this, (results) =>
        @loadedPaths = results
        resolve(results)

  resetPaths: ->
    delete @loadedPaths

  loadVariables: ->
    new Promise (resolve, reject) =>
      @loadPaths().then (paths) =>
        @scanPathsForVariables paths, (results) =>
          @variables = results
          resolve(results)

  getVariablesForFile: (path) ->
    return undefined unless @variables?

    @variables.filter (variable) ->
      variable.relativePath is path or variable.path is path

  deleteVariablesForFile: (path) ->
    return unless @variables?

    @variables = @variables.filter (variable) ->
      variable.relativePath isnt path and variable.path isnt path

  reloadVariablesForFile: (path) ->
    unless @variables?
      return Promise.reject("Can't reload a path that haven't been loaded yet")

    unless path in @loadedPaths
      return Promise.reject("Can't reload a path that is not legible")

    @deleteVariablesForFile(path)
    @loadVariablesForFile(path)

  loadVariablesForFile: (path) ->
    new Promise (resolve, reject) =>
      @scanPathsForVariables [path], (results) =>
        @variables = @variables.concat(results)
        resolve(results)

  scanPathsForVariables: (paths, callback) ->
    PathsScanner.startTask paths, (results) ->
      res.relativePath = atom.project.relativize(res.path) for res in results
      callback(results)

  getContext: ->
    new ColorContext(@getVariablesObject())

  getVariablesObject: ->
    return {} unless @variables?

    variablesObject = {}
    variablesObject[variable.name] = variable for variable in @variables
    variablesObject

  getColorVariables: ->
    context = @getContext()

    @variables.filter (variable) ->
      color = variable.color ? context.readColor(variable.value)
      variable.color ?= color if color? and !variable.color?

      color?

  getPalette: ->
    return new Palette unless @variables?

    colors = {}
    @getColorVariables().forEach (variable) -> colors[variable.name] = variable

    new Palette(colors)

  serialize: ->
    result = {deserializer: 'ColorProject'}

    if @variables?
      result.loadedPaths = @loadedPaths
      result.variables = @variables

    result
