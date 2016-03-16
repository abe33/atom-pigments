ExpressionsRegistry = require './expressions-registry'
VariableExpression = require './variable-expression'

module.exports = registry = new ExpressionsRegistry(VariableExpression)

registry.createExpression 'pigments:less', '^[ \\t]*(@[a-zA-Z0-9\\-_]+)\\s*:\\s*([^;\\n\\r]+);?', ['*']

# It catches sequences like `@mixin foo($foo: 10)` and ignores them.
registry.createExpression 'pigments:scss_params', '^[ \\t]*@(mixin|include|function)\\s+[a-zA-Z0-9\\-_]+\\s*\\([^\\)]+\\)', ['*'], (match, solver) ->
  [match] = match
  solver.endParsing(match.length - 1)

sass_handler = (match, solver) ->
  solver.appendResult([
    match[1]
    match[2]
    0
    match[0].length
  ])

  if match[1].match(/[-_]/)
    all_underscore = match[1].replace(/-/g, '_')
    all_hyphen = match[1].replace(/_/g, '-')

    if match[1] isnt all_underscore
      solver.appendResult([
        all_underscore
        match[2]
        0
        match[0].length
      ])
    if match[1] isnt all_hyphen
      solver.appendResult([
        all_hyphen
        match[2]
        0
        match[0].length
      ])

  solver.endParsing(match[0].length)

registry.createExpression 'pigments:scss', '^[ \\t]*(\\$[a-zA-Z0-9\\-_]+)\\s*:\\s*(.*?)(\\s*!default)?;', ['*'], sass_handler

registry.createExpression 'pigments:sass', '^[ \\t]*(\\$[a-zA-Z0-9\\-_]+)\\s*:\\s*([^\\{]*?)(\\s*!default)?$', ['*'], sass_handler

registry.createExpression 'pigments:css_vars', '(--[^\\s:]+):\\s*([^\\n;]+);', ['css'], (match, solver) ->
  solver.appendResult([
    "var(#{match[1]})"
    match[2]
    0
    match[0].length
  ])
  solver.endParsing(match[0].length)

registry.createExpression 'pigments:stylus_hash', '^[ \\t]*([a-zA-Z_$][a-zA-Z0-9\\-_]*)\\s*=\\s*\\{([^=]*)\\}', ['*'], (match, solver) ->
  buffer = ''
  [match, name, content] = match
  current = match.indexOf(content)
  scope = [name]
  scopeBegin = /\{/
  scopeEnd = /\}/
  commaSensitiveBegin = /\(|\[/
  commaSensitiveEnd = /\)|\]/
  inCommaSensitiveContext = false
  for char in content
    if scopeBegin.test(char)
      scope.push buffer.replace(/[\s:]/g, '')
      buffer = ''
    else if scopeEnd.test(char)
      scope.pop()
      return solver.endParsing(current) if scope.length is 0
    else if commaSensitiveBegin.test(char)
      buffer += char
      inCommaSensitiveContext = true
    else if inCommaSensitiveContext
      buffer += char
      inCommaSensitiveContext = !commaSensitiveEnd.test(char)
    else if /[,\n]/.test(char)
      buffer = buffer.replace(/\s+/g, '')
      if buffer.length
        [key, value] = buffer.split(/\s*:\s*/)

        solver.appendResult([
          scope.concat(key).join('.')
          value
          current - buffer.length - 1
          current
        ])

      buffer = ''
    else
      buffer += char

    current++

  scope.pop()
  if scope.length is 0
    solver.endParsing(current + 1)
  else
    solver.abortParsing()

registry.createExpression 'pigments:stylus', '^[ \\t]*([a-zA-Z_$][a-zA-Z0-9\\-_]*)\\s*=(?!=)\\s*([^\\n\\r;]*);?$', ['*']
