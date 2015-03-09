
module.exports =
class Palette
  constructor: (@colors={}) ->

  getColorsNames: -> Object.keys(@colors)

  getColorsCount: -> @getColorsNames().length
