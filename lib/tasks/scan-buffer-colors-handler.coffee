ColorScanner = require '../color-scanner'
ColorContext = require '../color-context'
registry = require '../color-expressions'
{namePrefixes} = require '../regexes'
ColorsChunkSize = 100

class BufferColorsScanner
  constructor: (config) ->
    {@buffer, variables} = config
    @context = new ColorContext(variables)
    @scanner = new ColorScanner({@context})
    @results = []

    if variables?.length > 0
      variableNames = variables.map (v) ->
        v.name.replace(/[-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&")
      .join('|')

      paletteRegexpString = "(#{namePrefixes})(#{variableNames})(?!_|-|\\w|\\d|[ \\t]*[\\.:=])"

      registry.createExpression 'variables', paletteRegexpString, 1, (match, expression, context) ->
        [d,d,name] = match
        baseColor = context.readColor(name)
        @colorExpression = name
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
