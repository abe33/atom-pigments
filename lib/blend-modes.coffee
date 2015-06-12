
module.exports =
  MULTIPLY: (v1, v2) ->
    v1 * v2 / 255

  SCREEN: (v1, v2) ->
    v1 + v2 - (v1 * v2 / 255)

  OVERLAY: (v1, v2) ->
    if v1 < 128
      2 * v1 * v2 / 255
    else
      255 - (2 * (255 - v1) * (255 - v2) / 255)

  DIFFERENCE: (v1, v2) -> Math.abs(v1 - v2)

  EXCLUSION: (v1, v2) ->
    cb = v1 / 255
    cs = v2 / 255
    (cb + cs - 2 * cb * cs) * 255

  AVERAGE: (v1, v2) -> (v1 + v2) / 2

  NEGATION: (v1,  v2) -> 255 - Math.abs(v1 + v2 - 255)

  SOFT_LIGHT: (v1, v2) ->
    cb = v1 / 255
    cs = v2 / 255
    d = 1
    e = cb

    if cs > 0.5
      e = 1
      d = if cb > 0.25 then Math.sqrt(cb) else ((16 * cb - 12) * cb + 4) * cb

    (cb - ((1 - (2 * cs)) * e * (d - cb))) * 255

  HARD_LIGHT: (v1, v2) ->
    module.exports.OVERLAY(v2, v1)

  COLOR_DODGE: (v1, v2) ->
    if v1 == 255 then v1 else Math.min(255, (v2 << 8) / (255 - v1))

  COLOR_BURN: (v1, v2) ->
    if v1 == 0 then v1 else Math.max(0, 255 - ((255 - v2 << 8) / v1))

  LINEAR_COLOR_DODGE: (v1, v2) ->
    Math.min v1 + v2, 255

  LINEAR_COLOR_BURN: (v1, v2) ->
    if v1 + v2 < 255 then 0 else v1 + v2 - 255
