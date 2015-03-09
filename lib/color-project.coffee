PathLoader = require './path-loader'
PathsScanner = require './paths-scanner'
ColorContext = require './color-context'
Palette = require './palette'

module.exports =
class ColorProject
  constructor: ({@ignores}) ->

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
        PathsScanner.startTask paths, (results) =>
          for res in results
            res.relativePath = atom.project.relativize(res.path)
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
