ColorScanner = require '../color-scanner'
ColorContext = require '../color-context'

ColorsChunkSize = 100

class BufferScanner
  constructor: (config) ->
    {@buffer, variables} = config
    @scanner = new ColorScanner
    @context = new ColorContext(variables)
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
  new BufferScanner(config).scan()
