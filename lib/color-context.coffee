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
    result = @parser.parse(@readColorExpression(value), @clone())
    if result?
      if keepAllVariables or value not in @usedVariables
        result.variables = result.variables.concat(@readUsedVariables())
      return result

  readFloat: (value) ->
    res = parseFloat(value)
    if isNaN(res) and @vars[value]?
      @usedVariables.push(value)
      res = parseFloat(@vars[value].value)
    res

  readInt: (value, base=10) ->
    res = parseInt(value, base)
    if isNaN(res) and @vars[value]?
      @usedVariables.push(value)
      res = parseInt(@vars[value].value, base)
    res

  readPercent: (value) ->
    if not /\d+/.test(value) and @vars[value]?
      @usedVariables.push(value)
      value = @vars[value].value

    Math.round(parseFloat(value) * 2.55)

  readIntOrPercent: (value) ->
    if not /\d+/.test(value) and @vars[value]?
      @usedVariables.push(value)
      value = @vars[value].value

    return NaN unless value?

    if value.indexOf('%') isnt -1
      res = Math.round(parseFloat(value) * 2.55)
    else
      res = parseInt(value)

    res

  readFloatOrPercent: (amount) ->
    if not /\d+/.test(amount) and @vars[amount]?
      @usedVariables.push(amount)
      amount = @vars[amount].value

    return NaN unless amount?

    if amount.indexOf('%') isnt -1
      res = parseFloat(amount) / 100
    else
      res = parseFloat(amount)
      res = res / 100 if res > 1
      res

    res
