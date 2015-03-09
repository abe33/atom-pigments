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
          @variables = results
          resolve(results)
