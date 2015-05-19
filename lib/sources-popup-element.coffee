{SpacePenDSL, EventsDelegation} = require 'atom-utils'

class SourcesPopupElement extends HTMLElement
  SpacePenDSL.includeInto(this)
  EventsDelegation.includeInto(this)

  @content: ->
    @tag 'atom-panel', class: 'modal overlay from-top'

  initialize: ({paths, resolve, reject}) ->

module.exports = SourcesPopupElement =
document.registerElement 'pigments-sources-popup', {
  prototype: SourcesPopupElement.prototype
}
