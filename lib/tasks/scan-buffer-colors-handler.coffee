ColorScanner = require '../color-scanner'
ColorContext = require '../color-context'
registry = require '../color-expressions'
{createVariableExpression} = require '../utils'
ColorsChunkSize = 100

class BufferColorsScanner
  constructor: (config) ->
    {@buffer, variables} = config
    @context = new ColorContext(variables)
    @scanner = new ColorScanner({@context})
    @results = []

    if variables?.length > 0
      registry.addExpression(@context.createVariableExpression())

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
