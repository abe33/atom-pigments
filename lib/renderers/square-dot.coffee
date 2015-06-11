DotRenderer = require './dot'

module.exports =
class SquareDotRenderer extends DotRenderer
  render: (colorMarker) ->
    properties = super
    properties.class += ' square'
    properties
