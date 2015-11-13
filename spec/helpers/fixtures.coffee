fs = require 'fs'
path = require 'path'

module.exports =
  jsonFixture: (paths...) -> (fixture, data) ->
    jsonPath = path.resolve(paths..., fixture)
    json = fs.readFileSync(jsonPath).toString()
    json = json.replace /#\{([\w\[\]]+)\}/g, (m,w) ->
      if match = /^\[(\w+)\]$/.exec(w)
        [_,w] = match
        data[w].shift()
      else
        data[w]

    JSON.parse(json)
