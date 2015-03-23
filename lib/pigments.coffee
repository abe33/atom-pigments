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
      description: "Glob patterns of files to scan for variables."
    ignoredNames:
      type: 'array'
      default: []
      description: "Glob patterns of files to ignore when scanning the project for variables."
    markerType:
      type: 'string'
      default: 'background'
      enum: ['background', 'outline', 'underline', 'dot']

  activate: (state) ->
    ColorProject = require './color-project'

    @project = new ColorProject(state ? {})

  deactivate: ->

  serialize: -> @project.serialize()

  getProject: -> @project
