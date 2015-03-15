VariableScanner = require '../variable-scanner'
ColorContext = require '../color-context'

VariablesChunkSize = 100

class BufferVariablesScanner
  constructor: (config) ->
    {@buffer} = config
    @scanner = new VariableScanner()
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
