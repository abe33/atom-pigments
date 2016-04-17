VariableScanner = require '../variable-scanner'
ColorContext = require '../color-context'
VariableExpression = require '../variable-expression'
ExpressionsRegistry = require '../expressions-registry'

VariablesChunkSize = 100

class BufferVariablesScanner
  constructor: (config) ->
    {@buffer, registry, scope} = config
    registry = ExpressionsRegistry.deserialize(registry, VariableExpression)
    @scanner = new VariableScanner({registry, scope})
    @results = []

  scan: ->
    lastIndex = 0
    while results = @scanner.search(@buffer, lastIndex)
      @results = @results.concat(results)

      @flushVariables() if @results.length >= VariablesChunkSize
      {lastIndex} = results

    @flushVariables()

  flushVariables: ->
    emit('scan-buffer:variables-found', @results)
    @results = []

module.exports = (config) ->
  new BufferVariablesScanner(config).scan()
