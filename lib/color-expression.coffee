Color = require './color'
{createVariableRegExpString} = require './regexes'

module.exports =
class ColorExpression
  @colorExpressionForContext: (context) ->
    @colorExpressionForColorVariables(context.getColorVariables())

  @colorExpressionRegexpForColorVariables: (colorVariables) ->
    createVariableRegExpString(colorVariables)

  @colorExpressionForColorVariables: (colorVariables) ->
    paletteRegexpString = @colorExpressionRegexpForColorVariables(colorVariables)

    new ColorExpression
      name: 'pigments:variables'
      regexpString: paletteRegexpString
      scopes: ['*']
      priority: 1
      handle: (match, expression, context) ->
        [_,name] = match
        return @invalid = true if context.readColorExpression(name) is name

        baseColor = context.readColor(name)
        @colorExpression = name
        @variables = baseColor?.variables

        return @invalid = true if context.isInvalid(baseColor)

        @rgba = baseColor.rgba

  constructor: ({@name, @regexpString, @scopes, @priority, @handle}) ->
    @regexp = new RegExp("^#{@regexpString}$")

  match: (expression) -> @regexp.test expression

  parse: (expression, context) ->
    return null unless @match(expression)

    color = new Color()
    color.colorExpression = expression
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
