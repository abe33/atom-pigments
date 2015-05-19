{CompositeDisposable} = require 'atom'
{SpacePenDSL, EventsDelegation} = require 'atom-utils'

class SourcesPopupElement extends HTMLElement
  SpacePenDSL.includeInto(this)
  EventsDelegation.includeInto(this)

  @content: ->
    @tag 'atom-panel', class: 'modal overlay from-top', =>
      @h3 'Warning!'
      @p =>
        @raw """
          Pigments has found <span class='text-danger'>0</span> files that
          can contains variables and the warning threshold is set to
          <span class='text-warning'>#{atom.config.get 'pigments.sourcesWarningThreshold'}</span>.
          All theses files aren't always necessary and can lead to performances
          issues so it's sometime better to either ignore some or all paths.
        """

      @p =>
        @raw """
          By choosing <code>Ignore Alert</code> the initializion will proceed as usual. By choosing <code>Drop Found Paths</code> no paths will be used at all.
        """

      @div class: 'block', =>
        @div class: 'btn-group pull-right', =>
          @button outlet: 'ignoreButton', class: 'btn', 'Ignore Alert'
          @button outlet: 'dropPathsButton', class: 'btn', 'Drop Found Paths'

  initialize: ({paths, resolve, reject}) ->
    @foundFiles = @querySelector('p .text-danger')
    @foundFiles.textContent = paths.length

    @subscriptions = new CompositeDisposable

    @subscriptions.add @subscribeTo @ignoreButton, 'click': -> resolve(paths)
    @subscriptions.add @subscribeTo @dropPathsButton, 'click': -> resolve([])

  detachedCallback: ->
    @subscriptions.dispose()

module.exports = SourcesPopupElement =
document.registerElement 'pigments-sources-popup', {
  prototype: SourcesPopupElement.prototype
}
