event = (type, properties={}) -> new Event type, properties

mouseEvent = (type, properties) ->
  defaults = {
    bubbles: true
    cancelable: (type isnt "mousemove")
    view: window
    detail: 0
    pageX: 0
    pageY: 0
    clientX: 0
    clientY: 0
    ctrlKey: false
    altKey: false
    shiftKey: false
    metaKey: false
    button: 0
    relatedTarget: undefined
  }

  properties[k] = v for k,v of defaults when not properties[k]?

  new MouseEvent type, properties

objectCenterCoordinates = (target) ->
  {top, left, width, height} = target.getBoundingClientRect()
  {x: left + width / 2, y: top + height / 2}

module.exports = {objectCenterCoordinates, mouseEvent, event}

['mousedown', 'mousemove', 'mouseup', 'click'].forEach (key) ->
  module.exports[key] = (target, x, y, cx, cy, btn) ->
    {x,y} = objectCenterCoordinates(target) unless x? and y?

    unless cx? and cy?
      cx = x
      cy = y

    target.dispatchEvent(mouseEvent key, {target, pageX: x, pageY: y, clientX: cx, clientY: cy, button: btn})

module.exports.mousewheel = (target, deltaX=0, deltaY=0) ->
  target.dispatchEvent(mouseEvent 'mousewheel', {target, deltaX, deltaY})

module.exports.change = (target) ->
  target.dispatchEvent(event 'change', {target})
