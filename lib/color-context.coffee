Color = require './color'
ColorParser = null
ColorExpression = require './color-expression'
{createVariableRegExpString} = require './regexes'

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

  createVariableExpression: ->
    paletteRegexpString = createVariableRegExpString(@variables)

    expression = new ColorExpression
      name: 'variables',
      regexpString: paletteRegexpString
      handle: (match, expression, context) ->
        [d,d,name] = match
        baseColor = context.readColor(name)
        @colorExpression = name

        return @invalid = true unless baseColor?

        @rgba = baseColor.rgba

    expression.priority = 1
    expression

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
    @parser.parse(@readColorExpression(value), this)

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
