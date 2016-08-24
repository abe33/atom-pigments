async = require 'async'
fs = require 'fs'
VariableScanner = require '../variable-scanner'
VariableExpression = require '../variable-expression'
ExpressionsRegistry = require '../expressions-registry'

class PathScanner
  constructor: (@filePath, scope, registry) ->
    @scanner = new VariableScanner({registry, scope})

  load: (done) ->
    currentChunk = ''
    currentLine = 0
    currentOffset = 0
    lastIndex = 0
    line = 0
    results = []

    readStream = fs.createReadStream(@filePath)

    readStream.on 'data', (chunk) =>
      currentChunk += chunk.toString()

      index = lastIndex

      while result = @scanner.search(currentChunk, lastIndex)
        result.range[0] += index
        result.range[1] += index

        for v in result
          v.path = @filePath
          v.range[0] += index
          v.range[1] += index
          v.definitionRange = result.range
          v.line += line
          lastLine = v.line

        results = results.concat(result)
        {lastIndex} = result

      if result?
        currentChunk = currentChunk[lastIndex..-1]
        line = lastLine
        lastIndex = 0

    readStream.on 'end', ->
      emit('scan-paths:path-scanned', results)
      done()

module.exports = ([paths, registry]) ->
  registry = ExpressionsRegistry.deserialize(registry, VariableExpression)
  async.each(
    paths,
    ([p, s], next) ->
      new PathScanner(p, s, registry).load(next)
    @async()
  )
