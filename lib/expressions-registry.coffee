ColorExpression = require './color-expression'

module.exports =
class ExpressionsRegistry
  # The {Object} where color expression handlers are stored
  constructor: ->
    @colorExpressions = {}

  getExpressions: ->
    (e for k,e of @colorExpressions).sort((a,b) -> b.priority - a.priority)

  # Public: Registers a color expression into the {Color} class.
  # The function will create an expression handler with the passed-in
  # arguments.
  #
  # name - A {String} to identify the expression
  # regexp - A {RegExp} {String} that matches the color notation. The
  #          expression can capture groups that will be used later in the
  #          color parsing phase
  # handle - A {Function} that takes a {Color} to modify and the {String}
  #          that matched during the lookup phase
  addExpression: (name, regexp, priority=0, handle=->) ->
    [priority, handle] = [0, priority] if typeof priority is 'function'
    @colorExpressions[name] = new ColorExpression(name, regexp, handle, priority)

  # Public: Removes an expression using the passed-in `name`.
  #
  # name - A {String} identifying the expression to remove
  removeExpression: (name) -> delete @colorExpressions[name]
