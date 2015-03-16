{Emitter, Range} = require 'atom'

module.exports =
class ProjectVariable
  constructor: (params={}, @project=null) ->
    {@name, @value, range, @path} = params
    @range = Range.fromObject(range)
    @emitter = new Emitter

  onDidDestroy: (callback) ->
    @emitter.on 'did-destroy', callback

  isColor: -> @getColor()?

  getColor: -> @color ?= @readColor()

  readColor: -> @project.getContext().readColor(@value)

  destroy: ->
    {@name, @value, @range, @path, @project, @color} = {}
    @emitter.emit('did-destroy')

  isEqual: (variable) ->
    @name is variable.name and
    @value is variable.value and
    @path is variable.path and
    @range.isEqual(variable.range)

  serialize: ->
    {@name, @value, @range, @path}
