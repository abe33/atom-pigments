{CompositeDisposable} = require 'atom'
{SpacePenDSL, EventsDelegation} = require 'atom-utils'

class SourcesPopupElement extends HTMLElement
  SpacePenDSL.includeInto(this)
  EventsDelegation.includeInto(this)

  @content: ->
    @tag 'atom-panel', class: 'modal overlay from-top', =>
      @h4 'Paths size threshold exceeded'
      @div class: 'inset-panel padded text-large', =>
        @p =>
          @raw """
            Pigments has found <span class='text-danger'>0</span> files that
            can contains variables and the warning threshold is set to
            <span class='text-danger'>#{atom.config.get 'pigments.sourcesWarningThreshold'}</span>.
            All theses files aren't always necessary and can lead to performances
            issues so it's sometime better ignore some paths.
          """

        @p class: 'text-warning', =>
          @raw """
            By choosing <kbd>Ignore Alert</kbd> the initializion will proceed as usual. By choosing <kbd>Drop Found Paths</kbd> no paths will be used at all.
          """

      @div class: 'block', =>
        @div class: 'select-list', =>
          @ol outlet: 'list', class: 'list-group mark-active', =>

      @div class: 'block', =>
        @button outlet: 'choosePathsButton', class: 'btn', 'Choose Paths'
        @button outlet: 'validatePathsButton', class: 'btn', 'Validate Paths'

        @div class: 'btn-group pull-right', =>
          @button outlet: 'ignoreButton', class: 'btn', 'Ignore Alert'
          @button outlet: 'dropPathsButton', class: 'btn', 'Drop Found Paths'

  initialize: ({paths, resolve, reject}) ->
    @foundFiles = @querySelector('p .text-danger')
    @foundFiles.textContent = paths.length
    @validatePathsButton.style.display = 'none'

    @subscriptions = new CompositeDisposable

    @subscriptions.add @subscribeTo @ignoreButton, 'click': -> resolve(paths)
    @subscriptions.add @subscribeTo @dropPathsButton, 'click': -> resolve([])
    @subscriptions.add @subscribeTo @choosePathsButton, 'click': =>
      @prepareList(paths, resolve)
    @subscriptions.add @subscribeTo @validatePathsButton, 'click': =>
      resolve Array::map.call @list.querySelectorAll('li.active'), (li) ->
        li.dataset.path

  detachedCallback: ->
    @subscriptions.dispose()

  prepareList: (paths, resolve) ->
    @validatePathsButton.style.display = ''
    @choosePathsButton.style.display = 'none'

    html = ''

    for p in paths
      html += """
      <li class='active' data-path='#{p}'>#{atom.project.relativize p}</li>
      """

    @list.innerHTML = html

module.exports = SourcesPopupElement =
document.registerElement 'pigments-sources-popup', {
  prototype: SourcesPopupElement.prototype
}
