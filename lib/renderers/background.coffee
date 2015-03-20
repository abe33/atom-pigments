
module.exports =
class BackgroundRenderer
  render: (colorMarker) ->
    region = document.createElement('div')
    region.className = 'region'
    [region]
