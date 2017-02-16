int = '\\d+'
decimal = "\\.#{int}"
float = "(?:#{int}#{decimal}|#{int}|#{decimal})"
percent = "#{float}%"
variables = '(?:@[a-zA-Z0-9\\-_]+|\\$[a-zA-Z0-9\\-_]+|[a-zA-Z_][a-zA-Z0-9\\-_]*)'
namePrefixes = '^| |\\t|:|=|,|\\n|\'|"|`|\\(|\\[|\\{|>'

module.exports =
  int: int
  float: float
  percent: percent
  optionalPercent: "#{float}%?"
  intOrPercent: "(?:#{percent}|#{int})"
  floatOrPercent: "(?:#{percent}|#{float})"
  comma: '\\s*,\\s*'
  notQuote: "[^\"'`\\n\\r]+"
  hexadecimal: '[\\da-fA-F]'
  ps: '\\(\\s*'
  pe: '\\s*\\)'
  variables: variables
  namePrefixes: namePrefixes
  createVariableRegExpString: (variables) ->
    variableNamesWithPrefix = []
    variableNamesWithoutPrefix = []
    withPrefixes = variables.filter (v) -> not v.noNamePrefix
    withoutPrefixes = variables.filter (v) -> v.noNamePrefix

    res = []

    if withPrefixes.length > 0
      for v in withPrefixes
        variableNamesWithPrefix.push v.name.replace(/[-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&")

      res.push "((?:#{namePrefixes})(#{variableNamesWithPrefix.join('|')})(\\s+!default)?(?!_|-|\\w|\\d|[ \\t]*[\\.:=]))"

    if withoutPrefixes.length > 0
      for v in withoutPrefixes
        variableNamesWithoutPrefix.push v.name.replace(/[-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&")

      res.push "(#{variableNamesWithoutPrefix.join('|')})"

    res.join('|')
