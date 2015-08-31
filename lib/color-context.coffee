Color = require './color'
ColorParser = null
ColorExpression = require './color-expression'

module.exports =
class ColorContext
  constructor: (options={}) ->
    {variables, colorVariables, @referenceVariable, @referencePath, @rootPaths, @parser, @colorVars, @vars, @defaultVars, @defaultColorVars, sorted} = options

    variables ?= []
    colorVariables ?= []
    @rootPaths ?= []
    @referencePath ?= @referenceVariable.path if @referenceVariable?

    if @sorted
      @variables = variables
      @colorVariables = colorVariables
    else
      @variables = variables.slice().sort(@sortPaths)
      @colorVariables = colorVariables.slice().sort(@sortPaths)

    unless @vars?
      @vars = {}
      @colorVars = {}
      @defaultVars = {}
      @defaultColorVars = {}

      for v in @variables
        @vars[v.name] = v
        @defaultVars[v.name] = v if v.path.match /\/.pigments$/

      for v in @colorVariables
        @colorVars[v.name] = v
        @defaultColorVars[v.name] = v if v.path.match /\/.pigments$/

    unless @parser?
      ColorParser = require './color-parser'
      @parser = new ColorParser

    @usedVariables = []

  sortPaths: (a,b) =>
    if @referencePath?
      return 0 if a.path is b.path
      return 1 if a.path is @referencePath
      return -1 if b.path is @referencePath

      rootReference = @rootPathForPath(@referencePath)
      rootA = @rootPathForPath(a.path)
      rootB = @rootPathForPath(b.path)

      return 0 if rootA is rootB
      return 1 if rootA is rootReference
      return -1 if rootB is rootReference

      0
    else
      0

  rootPathForPath: (path) ->
    return root for root in @rootPaths when path.indexOf("#{root}/") is 0

  clone: ->
    new ColorContext({
      @variables
      @colorVariables
      @referenceVariable
      @parser
      @vars
      @colorVars
      @defaultVars
      @defaultColorVars
      sorted: true
    })

  containsVariable: (variableName) -> variableName in @getVariablesNames()

  hasColorVariables: -> @colorVariables.length > 0

  getVariables: -> @variables

  getColorVariables: -> @colorVariables

  getVariablesNames: -> @varNames ?= Object.keys(@vars)

  getVariablesCount: -> @varCount ?= @getVariablesNames().length

  getValue: (value) ->
    [realValue, lastRealValue] = []

    while realValue = @vars[value]?.value
      @usedVariables.push(value)
      value = lastRealValue = realValue

    lastRealValue

  getColorValue: (value) ->
    [realValue, lastRealValue] = []

    while realValue = @colorVars[value]?.value
      @usedVariables.push(value)
      value = lastRealValue = realValue

    lastRealValue

  readUsedVariables: ->
    usedVariables = []
    usedVariables.push v for v in @usedVariables when v not in usedVariables
    @usedVariables = []
    usedVariables

  readColorExpression: (value) ->
    if @colorVars[value]?
      @usedVariables.push(value)
      @colorVars[value].value
    else
      value

  readColor: (value, keepAllVariables=false) ->
    realValue = @readColorExpression(value)
    result = @parser.parse(realValue, @clone())

    if result?
      if result.invalid and @defaultColorVars[realValue]?
        @usedVariables.push(realValue)
        result = @readColor(@defaultColorVars[realValue].value)
        value = realValue

    else if @defaultColorVars[value]?
      @usedVariables.push(realValue)
      result = @readColor(@defaultColorVars[value].value)

    if result? and (keepAllVariables or value not in @usedVariables)
      result.variables = result.variables.concat(@readUsedVariables())

    return result

  readFloat: (value) ->
    res = parseFloat(value)

    if isNaN(res) and @vars[value]?
      @usedVariables.push value
      res = @readFloat(@vars[value].value)

    if isNaN(res) and @defaultVars[value]?
      @usedVariables.push value
      res = @readFloat(@defaultVars[value].value)

    res

  readInt: (value, base=10) ->
    res = parseInt(value, base)

    if isNaN(res) and @vars[value]?
      @usedVariables.push value
      res = @readInt(@vars[value].value)

    if isNaN(res) and @defaultVars[value]?
      @usedVariables.push value
      res = @readInt(@defaultVars[value].value)

    res

  readPercent: (value) ->
    if not /\d+/.test(value) and @vars[value]?
      @usedVariables.push value
      value = @readPercent(@vars[value].value)

    if not /\d+/.test(value) and @defaultVars[value]?
      @usedVariables.push value
      value = @readPercent(@defaultVars[value].value)

    Math.round(parseFloat(value) * 2.55)

  readIntOrPercent: (value) ->
    if not /\d+/.test(value) and @vars[value]?
      @usedVariables.push value
      value = @readIntOrPercent(@vars[value].value)

    if not /\d+/.test(value) and @defaultVars[value]?
      @usedVariables.push value
      value = @readIntOrPercent(@defaultVars[value].value)

    return NaN unless value?
    return value if typeof value is 'number'

    if value.indexOf('%') isnt -1
      res = Math.round(parseFloat(value) * 2.55)
    else
      res = parseInt(value)

    res

  readFloatOrPercent: (value) ->
    if not /\d+/.test(value) and @vars[value]?
      @usedVariables.push value
      value = @readFloatOrPercent(@vars[value].value)

    if not /\d+/.test(value) and @defaultVars[value]?
      @usedVariables.push value
      value = @readFloatOrPercent(@defaultVars[value].value)

    return NaN unless value?
    return value if typeof value is 'number'

    if value.indexOf('%') isnt -1
      res = parseFloat(value) / 100
    else
      res = parseFloat(value)
      res = res / 100 if res > 1
      res

    res
