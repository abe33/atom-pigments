[createVariableRegExpString, Color] = []

module.exports =
class ColorExpression
  @colorExpressionForContext: (context) ->
    @colorExpressionForColorVariables(context.getColorVariables())

  @colorExpressionRegexpForColorVariables: (colorVariables) ->
    unless createVariableRegExpString?
      {createVariableRegExpString} = require './regexes'

    createVariableRegExpString(colorVariables)

  @colorExpressionForColorVariables: (colorVariables) ->
    paletteRegexpString = @colorExpressionRegexpForColorVariables(colorVariables)

    new ColorExpression
      name: 'pigments:variables'
      regexpString: paletteRegexpString
      scopes: ['*']
      priority: 1
      handle: (match, expression, context) ->
        [_, _,name] = match

        name = match[0] unless name?

        evaluated = context.readColorExpression(name)
        return @invalid = true if evaluated is name

        baseColor = context.readColor(evaluated)
        @colorExpression = name
        @variables = baseColor?.variables

        return @invalid = true if context.isInvalid(baseColor)

        @rgba = baseColor.rgba

  constructor: ({@name, @regexpString, @scopes, @priority, @handle}) ->
    @regexp = new RegExp("^#{@regexpString}$")

  match: (expression) -> @regexp.test expression

  parse: (expression, context) ->
    return null unless @match(expression)

    Color ?= require './color'

    color = new Color()
    color.colorExpression = expression
    color.expressionHandler = @name
    @handle.call(color, @regexp.exec(expression), expression, context)
    color

  search: (text, start=0) ->
    results = undefined
    re = new RegExp(@regexpString, 'g')
    re.lastIndex = start
    if [match] = re.exec(text)
      {lastIndex} = re
      range = [lastIndex - match.length, lastIndex]
      results =
        range: range
        match: text[range[0]...range[1]]

    results
