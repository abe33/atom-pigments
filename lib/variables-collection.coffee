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
    @variablesByPath = {}
    @colorVariables = []

  onDidChange: (callback) ->
    @emitter.on 'did-change', callback

  getColorVariables: -> @colorVariables

  find: (properties) ->
    keys = Object.keys(properties)
    compare = (k) ->
      if v[k]?.isEqual?
        v[k].isEqual(properties[k])
      else
        v[k] is properties[k]

    for v in @variables
      return v if keys.every(compare)

  add: (variable, batch=false) ->
    [status, v] = @getVariableStatus(variable)

    switch status
      when 'moved'
        v.range = variable.range
        v.bufferRange = variable.bufferRange

      when 'updated'
        wasColor = v.isColor
        v.value = variable.value

        context = @getContext()
        color = context.readColor(variable.value)

        if color?
          v.color = color
          v.isColor = true

          unless wasColor
            @colorVariables.push(v)

        else if wasColor
          @colorVariables = @colorVariables.filter (vv) -> vv is v

        if batch
          return ['updated', v]
        else
          @emitChangeEvent([],[],[v])

      when 'created'
        context = @getContext()
        color = context.readColor(variable.value)

        if color?
          variable.color = color
          variable.isColor = true
          @colorVariables.push(variable)

        @variables.push variable

        @variablesByPath[variable.path] ?= []
        @variablesByPath[variable.path].push(variable)

        if batch
          return ['created', variable]
        else
          @emitChangeEvent([variable])

  addMany: (variables) ->
    results =
      created: []
      destroyed: []
      updated: []

    for variable in variables
      res = @add(variable, true)
      if res?
        [status, v] = res
        results[status].push(v)

    @emitChangeEvent(results.created, results.destroyed, results.updated)

  remove: (variable, batch=false) ->

  removeMany: (variables) ->
    @remove(variable, true) for variable in variables

  getContext: -> new ColorContext(@variables, @colorVariables)

  getVariableStatus: (variable) ->
    return ['created', variable] unless @variablesByPath[variable.path]?

    for v in @variablesByPath[variable.path]
      sameName = v.name is variable.name
      sameValue = v.value is variable.value
      sameRange = if v.bufferRange? and variable.bufferRange?
        v.bufferRange.isEqual(variable.bufferRange)
      else
        v.range[0] is variable.range[0] and v.range[1] is variable.range[1]

      if sameName and sameValue
        if sameRange
          return ['unchanged', v]
        else
          return ['moved', v]
      else if sameName
        return ['updated', v]

    return ['created', variable]

  emitChangeEvent: (created=[], destroyed=[], updated=[]) ->
    if created.length or destroyed.length or updated.length
      @emitter.emit 'did-change', {created, destroyed, updated}
