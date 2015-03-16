{Emitter, Range} = require 'atom'

nextId = 1

module.exports =
class ProjectVariable

  constructor: (params={}, @project=null) ->
    {@name, @value, @range, @path, @bufferRange} = params
    @id = nextId++
    @emitter = new Emitter

  onDidDestroy: (callback) ->
    @emitter.on 'did-destroy', callback

  isColor: -> @getColor()?

  getColor: -> @color ?= @readColor()

  readColor: -> @project.getContext().readColor(@value)

  destroy: ->
    @emitter.emit('did-destroy')
    {@name, @value, @range, @path, @project, @color} = {}

  isEqual: (variable) ->
    bool = @name is variable.name and
    @value is variable.value and
    @path is variable.path

    bool &&= if @bufferRange? and variable.bufferRange?
      @bufferRange.isEqual(variable.bufferRange)
    else
      @range[0] is variable.range[0] and @range[1] is variable.range[1]

    bool

  serialize: ->
    {@name, @value, @range, @path}
