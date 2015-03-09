PathLoader = require './path-loader'

module.exports =
class ColorProject
  constructor: ({@ignores}) ->

  loadPaths: ->
    return Promise.resolve @loadedPaths if @loadedPaths?

    new Promise (resolve, reject) =>
      PathLoader.startTask this, (results) =>
        @loadedPaths = results
        resolve(results)

  resetPaths: ->
    delete @loadedPaths
