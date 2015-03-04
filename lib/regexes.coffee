int = '\\d+'
decimal = "\\.#{int}"
float = "(?:#{int}|#{int}#{decimal}|#{decimal})"
percent = "#{float}%"
variables = '(@[a-zA-Z0-9\\-_]+|\\$[a-zA-Z0-9\\-_]+|[a-zA-Z_][a-zA-Z0-9\\-_]*)'

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
  namePrefixes: '^| |:|=|,|\\n|\'|"|\\(|\\[|\\{'
