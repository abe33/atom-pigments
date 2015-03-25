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
  intOrPercent: "(#{percent}|#{int})"
  floatOrPercent: "(#{percent}|#{float})"
  comma: '\\s*,\\s*'
  notQuote: "[^\"'\\n]+"
  hexa: '[\\da-fA-F]'
  ps: '\\(\\s*'
  pe: '\\s*\\)'
  variables: variables
  namePrefixes: namePrefixes
  createVariableRegExpString: (variables) ->
    variableNames = variables.map (v) ->
      v.name.replace(/[-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&")
    .join('|')

    "(#{namePrefixes})(#{variableNames})(?!_|-|\\w|\\d|[ \\t]*[\\.:=])"
