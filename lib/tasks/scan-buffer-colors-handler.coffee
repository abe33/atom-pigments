ColorScanner = require '../color-scanner'
ColorContext = require '../color-context'
{getRegistry} = require '../color-expressions'
{createVariableExpression} = require '../utils'
ColorsChunkSize = 100

class BufferColorsScanner
  constructor: (config) ->
    {@buffer, variables, colorVariables} = config
    @context = new ColorContext(variables, colorVariables)
    @scanner = new ColorScanner({@context})
    @results = []

  scan: ->
    lastIndex = 0
    while result = @scanner.search(@buffer, lastIndex)
      @results.push(result)

      @flushColors() if @results.length >= ColorsChunkSize
      {lastIndex} = result

    @flushColors()

  flushColors: ->
    emit('scan-buffer:colors-found', @results)
    @results = []

module.exports = (config) ->
  new BufferColorsScanner(config).scan()
