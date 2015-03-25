ColorScanner = require '../color-scanner'
ColorContext = require '../color-context'
registry = require '../color-expressions'
{createVariableRegExpString} = require '../regexes'
ColorsChunkSize = 100

class BufferColorsScanner
  constructor: (config) ->
    {@buffer, variables} = config
    @context = new ColorContext(variables)
    @scanner = new ColorScanner({@context})
    @results = []

    if variables?.length > 0
      paletteRegexpString = createVariableRegExpString(variables)

      registry.createExpression 'variables', paletteRegexpString, 1, (match, expression, context) ->
        [d,d,name] = match
        baseColor = context.readColor(name)
        @colorExpression = name

        return @invalid = true unless baseColor?

        @rgba = baseColor.rgba

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
