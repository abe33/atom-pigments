
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
    collator = new Intl.Collator("en-US", numeric: true)
    @tuple().sort(collator.compare)

  getColorsNames: -> Object.keys(@colors)

  getColorsCount: -> @getColorsNames().length

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
