{EventsDelegation} = require 'atom-utils'
CompositeDisposable = null

module.exports =
class StickyTitle
  EventsDelegation.includeInto(this)

  constructor: (@stickies, @scrollContainer) ->
    CompositeDisposable ?= require('atom').CompositeDisposable

    @subscriptions = new CompositeDisposable
    Array::forEach.call @stickies, (sticky) ->
      sticky.parentNode.style.height = sticky.offsetHeight + 'px'
      sticky.style.width = sticky.offsetWidth + 'px'

    @subscriptions.add @subscribeTo @scrollContainer, 'scroll': (e) =>
      @scroll(e)

  dispose: ->
    @subscriptions.dispose()
    @stickies = null
    @scrollContainer = null

  scroll: (e) ->
    delta = if @lastScrollTop
      @lastScrollTop - @scrollContainer.scrollTop
    else
      0

    Array::forEach.call @stickies, (sticky, i) =>
      nextSticky = @stickies[i + 1]
      prevSticky = @stickies[i - 1]
      scrollTop = @scrollContainer.getBoundingClientRect().top
      parentTop = sticky.parentNode.getBoundingClientRect().top
      {top} = sticky.getBoundingClientRect()

      if parentTop < scrollTop
        unless sticky.classList.contains('absolute')
          sticky.classList.add 'fixed'
          sticky.style.top = scrollTop + 'px'

          if nextSticky?
            nextTop = nextSticky.parentNode.getBoundingClientRect().top
            if top + sticky.offsetHeight >= nextTop
              sticky.classList.add('absolute')
              sticky.style.top = @scrollContainer.scrollTop + 'px'

      else
        sticky.classList.remove 'fixed'

        if prevSticky? and prevSticky.classList.contains('absolute')
          prevTop = prevSticky.getBoundingClientRect().top
          prevTop -= prevSticky.offsetHeight if delta < 0

          if scrollTop <= prevTop
            prevSticky.classList.remove('absolute')
            prevSticky.style.top = scrollTop + 'px'

    @lastScrollTop = @scrollContainer.scrollTop
