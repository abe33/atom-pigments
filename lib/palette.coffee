
module.exports =
class Palette
  constructor: (@variables=[]) ->

  sortedByColor: ->
    @variables.slice().sort ({color:a}, {color:b}) => @compareColors(a,b)

  sortedByName: ->
    collator = new Intl.Collator("en-US", numeric: true)
    @variables.slice().sort ({name:a}, {name:b}) -> collator.compare(a,b)

  getColorsNames: -> @variables.map (v) -> v.name

  getColorsCount: -> @variables.length

  eachColor: (iterator) -> iterator(v) for v in @variables

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
