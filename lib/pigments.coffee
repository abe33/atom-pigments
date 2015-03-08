{CompositeDisposable} = require 'atom'

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

  deactivate: ->
