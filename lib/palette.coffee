
module.exports =
class Palette
  constructor: (@colors={}) ->

  getColorsNames: -> Object.keys(@colors)

  getColorsCount: -> @getColorsNames().length

  getUniqueColorsMap: ->
    map = new Map()

    colors = []

    findColor = (color) -> return col for col in colors when col.isEqual(color)

    for k,v of @colors
      if key = findColor(v)
        map.get(key).push(k)
      else
        map.set(v, [k])
        colors.push(v)

    return map
