
module.exports =
class Palette
  constructor: (@colors={}) ->

  getColor: (name) -> @colors[name]

  getNames: (ref) ->
    @tuple()
    .filter ([_,color]) -> color.isEqual(ref)
    .map ([name]) -> name

  sortedByColor: ->
    @tuple().sort ([_, a], [__, b]) => @compareColors(a,b)

  sortedByName: ->
    @tuple().sort ([a],[b]) -> if a > b then 1 else if a < b then -1 else 0

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

  eachColor: (iterator) -> iterator(k,v) for k,v of @colors

  tuple: -> @eachColor (name, color) -> [name, color]

  compareColors: (a,b) ->
    [aHue, aSaturation, aLightness] = a.hsl
    [bHue, bSaturation, bLightness] = b.hsl
    if aHue < bHue
      -1
    else if aHue > bHue
      1
    else if aSaturation < bSaturation
      -1
    else if aSaturation > bSaturation
      1
    else if aLightness < bLightness
      -1
    else if aLightness > bLightness
      1
    else
      0
