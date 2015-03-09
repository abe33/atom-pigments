PathLoader = require './path-loader'
PathsScanner = require './paths-scanner'

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
