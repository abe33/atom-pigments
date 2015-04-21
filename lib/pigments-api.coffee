
module.exports =
class PigmentsAPI
  constructor: (@project) ->

  getProject: -> @project

  getPalette: -> @project.getPalette()

  getVariables: -> @project.getVariables()

  getColorVariables: -> @project.getColorVariables()

  observeColorBuffers: (callback) -> @project.observeColorBuffers(callback)
