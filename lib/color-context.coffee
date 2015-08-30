Color = require './color'
ColorParser = null
ColorExpression = require './color-expression'

module.exports =
class ColorContext
  constructor: (@variables=[], @colorVariables=[], @parser) ->
    @vars = {}
    @colorVars = {}

    @vars[v.name] = v for v in @variables
    @colorVars[v.name] = v for v in @colorVariables

    unless @parser?
      ColorParser = require './color-parser'
      @parser = new ColorParser

    @usedVariables = []

  clone: -> new ColorContext(@variables, @colorVariables, @parser)

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
    if realValue = @getColorValue(value)
      realValue
    else
      value

  readColor: (value, keepAllVariables=false) ->
    result = @parser.parse(@readColorExpression(value), @clone())
    if result?
      if keepAllVariables or value not in @usedVariables
        result.variables = result.variables.concat(@readUsedVariables())
      return result

  readFloat: (value) ->
    res = parseFloat(value)
    if isNaN(res) and realValue = @getValue(value)
      res = parseFloat(realValue)
    res

  readInt: (value, base=10) ->
    res = parseInt(value, base)
    if isNaN(res) and realValue = @getValue(value)
      console.log realValue
      res = parseInt(realValue, base)
      console.log res

    res

  readPercent: (value) ->
    if not /\d+/.test(value) and realValue = @getValue(value)
      value = realValue

    Math.round(parseFloat(value) * 2.55)

  readIntOrPercent: (value) ->
    if not /\d+/.test(value) and realValue = @getValue(value)
      value = realValue

    return NaN unless value?

    if value.indexOf('%') isnt -1
      res = Math.round(parseFloat(value) * 2.55)
    else
      res = parseInt(value)

    res

  readFloatOrPercent: (value) ->
    if not /\d+/.test(value) and realValue = @getValue(value)
      value = realValue

    return NaN unless value?

    if value.indexOf('%') isnt -1
      res = parseFloat(value) / 100
    else
      res = parseFloat(value)
      res = res / 100 if res > 1
      res

    res
