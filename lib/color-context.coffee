Color = require './color'
ColorParser = null
ColorExpression = require './color-expression'

module.exports =
class ColorContext
  constructor: (@variables=[], @parser) ->
    @vars = {}
    @vars[v.name] = v for v in @variables

    unless @parser?
      ColorParser = require './color-parser'
      @parser = new ColorParser

    @usedVariables = []

  containsVariable: (variableName) -> variableName in @getVariablesNames()

  hasVariables: -> @variables.length > 0

  getVariables: -> @variables

  getVariablesNames: -> @varNames ?= Object.keys(@vars)

  getVariablesCount: -> @varCount ?= @getVariablesNames().length

  readUsedVariables: ->
    usedVariables = []
    usedVariables.push v for v in @usedVariables when v not in usedVariables
    @usedVariables = []
    usedVariables

  readColorExpression: (value) ->
    if @vars[value]?
      @usedVariables.push(value)
      @vars[value].value
    else
      value

  readColor: (value) ->
    result = @parser.parse(@readColorExpression(value), this)
    result if result?.isValid()

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

    res
