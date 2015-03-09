
module.exports =
class ProjectVariable
  constructor: (params={}, @project=null) ->
    {@name, @value, @range, @path} = params

  isColor: -> @getColor()?

  getColor: -> @color ?= @readColor()

  readColor: -> @project.getContext().readColor(@value)

  destroy: ->
    {@name, @value, @range, @path, @project, @color} = {}

  serialize: ->
    {@name, @value, @range, @path}
