{Emitter} = require 'atom'
ColorContext = require './color-context'

module.exports =
class VariablesCollection
  Object.defineProperty @prototype, 'length', {
    get: -> @variables.length
    enumerable: true
  }

  constructor: ->
    @emitter = new Emitter
    @variables = []
    @variableNames = []
    @colorVariables = []
    @variablesByPath = {}
    @dependencyGraph = {}

  onDidChange: (callback) ->
    @emitter.on 'did-change', callback

  getColorVariables: -> @colorVariables

  find: (properties) -> @findAll(properties)?[0]

  findAll: (properties={}) ->
    keys = Object.keys(properties)
    return null if keys.length is 0

    @variables.filter (v) -> keys.every (k) ->
      if v[k]?.isEqual?
        v[k].isEqual(properties[k])
      else if Array.isArray(b = properties[k])
        a = v[k]
        a.length is b.length and a.every (value) -> value in b
      else
        v[k] is properties[k]

  updatePathCollection: (path, collection) ->
    pathCollection = @variablesByPath[path]

    results = @addMany(collection, true)

    destroyed = []
    for v in pathCollection
      [status] = @getVariableStatusInCollection(v, collection)
      destroyed.push(@remove(v, true)) if status is 'created'

    results.destroyed = destroyed if destroyed.length > 0
    results = @updateDependencies(results)
    @deleteVariableReferences(v) for v in destroyed
    @emitChangeEvent(results)

  add: (variable, batch=false) ->
    [status, previousVariable] = @getVariableStatus(variable)

    switch status
      when 'moved'
        v.range = variable.range
        v.bufferRange = variable.bufferRange
      when 'updated'
        @updateVariable(previousVariable, variable, batch)
      when 'created'
        @createVariable(variable, batch)

  addMany: (variables, batch=false) ->
    results = {}

    for variable in variables
      res = @add(variable, true)
      if res?
        [status, v] = res

        results[status] ?= []
        results[status].push(v)

    if batch
      results
    else
      @emitChangeEvent(@updateDependencies(results))

  remove: (variable, batch=false) ->
    variable = @find(variable)

    return unless variable?

    @variables = @variables.filter (v) -> v isnt variable
    if variable.isColor
      @colorVariables = @colorVariables.filter (v) -> v isnt variable

    if batch
      return variable
    else
      results = @updateDependencies(destroyed: [variable])

      @deleteVariableReferences(variable)
      @emitChangeEvent(results)

  removeMany: (variables, batch=false) ->
    destroyed = []
    for variable in variables
      destroyed.push @remove(variable, true)

    results = {destroyed}

    if batch
      results
    else
      results = @updateDependencies(results)
      @deleteVariableReferences(v) for v in destroyed
      @emitChangeEvent(results)

  deleteVariableReferences: (variable) ->
    dependencies = @getVariableDependencies(variable)

    a = @variablesByPath[variable.path]
    a.splice(a.indexOf(variable), 1)

    a = @variableNames
    a.splice(a.indexOf(variable.name), 1)

    @removeDependencies(variable.name, dependencies)

    delete @dependencyGraph[variable.name]

  getContext: -> new ColorContext(@variables, @colorVariables)

  updateVariable: (previousVariable, variable, batch) ->
    previousDependencies = @getVariableDependencies(previousVariable)
    previousVariable.value = variable.value
    previousVariable.range = variable.range
    previousVariable.bufferRange = variable.bufferRange

    @evaluateVariableColor(previousVariable, previousVariable.isColor)
    newDependencies = @getVariableDependencies(previousVariable)

    {removed, added} = @diffArrays(previousDependencies, newDependencies)
    @removeDependencies(variable.name, removed)
    @addDependencies(variable.name, added)

    if batch
      return ['updated', previousVariable]
    else
      @emitChangeEvent(@updateDependencies(updated: [previousVariable]))

  createVariable: (variable, batch) ->
    @variableNames.push(variable.name)
    @variables.push variable

    @variablesByPath[variable.path] ?= []
    @variablesByPath[variable.path].push(variable)

    @evaluateVariableColor(variable)
    @buildDependencyGraph(variable)

    if batch
      return ['created', variable]
    else
      @emitChangeEvent(@updateDependencies(created: [variable]))

  evaluateVariableColor: (variable, wasColor=false) ->
    context = @getContext()
    color = context.readColor(variable.value, true)

    if color?
      return false if wasColor and color.isEqual(variable.color)

      variable.color = color
      variable.isColor = true

      @colorVariables.push(variable) unless variable in @colorVariables
      return true

    else if wasColor
      delete variable.color
      variable.isColor = false
      @colorVariables = @colorVariables.filter (v) -> v isnt variable
      return true

  getVariableStatus: (variable) ->
    return ['created', variable] unless @variablesByPath[variable.path]?
    @getVariableStatusInCollection(variable, @variablesByPath[variable.path])

  getVariableStatusInCollection: (variable, collection) ->
    for v in collection
      status = @compareVariables(v, variable)

      switch status
        when 'identical' then return ['unchanged', v]
        when 'move' then return ['moved', v]
        when 'update' then return ['updated', v]
        when 'different' then return ['created', variable]

    return ['created', variable]

  compareVariables: (v1, v2) ->
    sameName = v1.name is v2.name
    sameValue = v1.value is v2.value
    sameLine = v1.line is v2.line
    sameRange = if v1.bufferRange? and v2.bufferRange?
      v1.bufferRange.isEqual(v2.bufferRange)
    else
      v1.range[0] is v2.range[0] and v1.range[1] is v2.range[1]

    if sameName and sameValue
      if sameRange
        'identical'
      else
        'move'
    else if sameName
      if sameRange or sameLine
        'update'
      else
        'different'

  buildDependencyGraph: (variable) ->
    dependencies = @getVariableDependencies(variable)
    for dependency in dependencies
      a = @dependencyGraph[dependency] ?= []
      a.push(variable.name) unless variable.name in a

  getVariableDependencies: (variable) ->
    dependencies = []
    dependencies.push(variable.value) if variable.value in @variableNames

    if variable.color?.variables.length > 0
      variables = variable.color.variables

      for v in variables
        dependencies.push(v) unless v in dependencies

    dependencies

  collectVariablesByName: (names) ->
    variables = []
    variables.push v for v in @variables when v.name in names
    variables

  removeDependencies: (from, to) ->
    for v in to
      if dependencies = @dependencyGraph[v]
        dependencies.splice(dependencies.indexOf(from), 1)

        delete @dependencyGraph[v] if dependencies.length is 0

  addDependencies: (from, to) ->
    for v in to
      @dependencyGraph[v] ?= []
      @dependencyGraph[v].push(from)

  updateDependencies: ({created, updated, destroyed}) ->
    variables = []
    dirtyVariableNames = []

    if created?
      variables = variables.concat(created)
      createdVariableNames = created.map (v) -> v.name
    else
      createdVariableNames = []

    variables = variables.concat(updated) if updated?
    variables = variables.concat(destroyed) if destroyed?

    for variable in variables
      if dependencies = @dependencyGraph[variable.name]
        for name in dependencies
          if name not in dirtyVariableNames and name not in createdVariableNames
            dirtyVariableNames.push(name)

    dirtyVariables = @collectVariablesByName(dirtyVariableNames)

    for variable in dirtyVariables
      if @evaluateVariableColor(variable, variable.isColor)
        updated ?= []
        updated.push(variable)

    {created, destroyed, updated}

  emitChangeEvent: ({created, destroyed, updated}) ->
    if created?.length or destroyed?.length or updated?.length
      @emitter.emit 'did-change', {created, destroyed, updated}

  diffArrays: (a,b) ->
    removed = []
    added = []

    removed.push(v) for v in a when v not in b
    added.push(v) for v in b when v not in a

    {removed, added}
