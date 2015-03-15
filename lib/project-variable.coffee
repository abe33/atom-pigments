{Emitter} = require 'atom'

module.exports =
class ProjectVariable
  constructor: (params={}, @project=null) ->
    {@name, @value, @range, @path} = params
    @emitter = new Emitter

  onDidDestroy: (callback) ->
    @emitter.on 'did-destroy', callback

  isColor: -> @getColor()?

  getColor: -> @color ?= @readColor()

  readColor: -> @project.getContext().readColor(@value)

  destroy: ->
    {@name, @value, @range, @path, @project, @color} = {}
    @emitter.emit('did-destroy')

  serialize: ->
    {@name, @value, @range, @path}
