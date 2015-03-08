
module.exports =
class ColorProject
  constructor: ({@project, @ignores}) ->

  loadPaths: ->
    new Promise (resolve, reject) ->
      resolve [
        'styles/buttons.styl'
        'styles/variables.styl'
      ]
