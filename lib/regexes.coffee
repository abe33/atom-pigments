int = '\\d+'
decimal = "\\.#{int}"
float = "(?:#{int}|#{int}#{decimal}|#{decimal})"
percent = "#{float}%"
variables = '(@[a-zA-Z0-9\\-_]+|\\$[a-zA-Z0-9\\-_]+|[a-zA-Z_][a-zA-Z0-9\\-_]*)'
namePrefixes = '^| |:|=|,|\\n|\'|"|\\(|\\[|\\{'

module.exports =
  int: int
  float: float
  percent: percent
  optionalPercent: "#{float}%?"
  intOrPercent: "(#{percent}|#{int})"
  floatOrPercent: "(#{percent}|#{float})"
  comma: '\\s*,\\s*'
  notQuote: "[^\"'\\n]+"
  hexadecimal: '[\\da-fA-F]'
  ps: '\\(\\s*'
  pe: '\\s*\\)'
  variables: variables
  namePrefixes: namePrefixes
  createVariableRegExpString: (variables) ->
    variableNames = []
    for v in variables
      variableNames.push v.name.replace(/[-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&")
    variableNames = variableNames.join('|')

    "(#{namePrefixes})(#{variableNames})(?!_|-|\\w|\\d|[ \\t]*[\\.:=])"
