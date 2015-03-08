PathLoader = require './path-loader'

module.exports =
class ColorProject
  constructor: ({@ignores}) ->

  loadPaths: ->
    new Promise (resolve, reject) =>
      PathLoader.startTask this, (results) -> resolve(results)
