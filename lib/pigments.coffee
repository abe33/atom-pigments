{CompositeDisposable} = require 'atom'
[ColorProject, PigmentsProvider] = []

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
    autocompleteScopes:
      type: 'array'
      default: [
        '.source.css'
        '.source.css.less'
        '.source.sass'
        '.source.css.scss'
        '.source.stylus'
      ]
      description: 'The autocomplete provider will only complete color names in editors whose scope is present in this list.'
      items:
        type: 'string'
    extendAutocompleteToVariables:
      type: 'boolean'
      default: true
      description: 'When enabled, the autocomplete provider will also provides completion for non-color variables.'

  activate: (state) ->
    ColorProject ?= require './color-project'

    @project = new ColorProject(state ? {})

  deactivate: ->

  provide: ->
    PigmentsProvider ?= require './pigments-provider'
    new PigmentsProvider(@getProject())

  serialize: -> @project.serialize()

  getProject: -> @project
