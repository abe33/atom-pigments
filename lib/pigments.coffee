{CompositeDisposable} = require 'atom'
ColorProject = null

module.exports =
  config:
    traverseIntoSymlinkDirectories:
      type: 'boolean'
      default: false
    sourceNames:
      type: 'array'
      default: [
        '**/*.styl'
        '**/*.less'
        '**/*.sass'
        '**/*.scss'
      ]
    ignoredNames:
      type: 'array'
      default: []

  activate: (state) ->
    ColorProject = require './color-project'

    @project = new ColorProject(state ? {})

  deactivate: ->

  serialize: -> @project.serialize()

  getProject: -> @project
