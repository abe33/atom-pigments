{CompositeDisposable} = require 'atom'
{SpacePenDSL, EventsDelegation} = require 'atom-utils'
minimatch = require 'minimatch'

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
            By choosing <kbd>Ignore Alert</kbd> the initializion will proceed as usual. By choosing <kbd>Drop Found Paths</kbd> a new ignore rule with value <kbd>'*'</kbd> will be added to the project ignore rules.
          """

      @div outlet: 'ignoreRulesBlock', class: 'block', style: 'display: none', =>
        @div class: 'select-list', =>
          @ol outlet: 'list', class: 'list-group mark-active'

        @tag 'atom-text-editor', mini: true, outlet: 'ignoreRulesEditorView', placeholder: 'Use glob-like pattern to filter the paths list above'

      @div class: 'block', =>
        @button outlet: 'addIgnoreRuleButton', class: 'btn', 'Choose Paths'
        @button outlet: 'validatePathsButton', class: 'btn', 'Validate Paths'

        @div class: 'btn-group pull-right', =>
          @button outlet: 'ignoreButton', class: 'btn', 'Ignore Alert'
          @button outlet: 'dropPathsButton', class: 'btn', 'Drop Found Paths'

  initialize: ({paths, resolve, reject}) ->
    @foundFiles = @querySelector('p .text-danger')
    @foundFiles.textContent = paths.length
    @validatePathsButton.style.display = 'none'
    @ignoreRulesEditor = @ignoreRulesEditorView.getModel()

    @subscriptions = new CompositeDisposable

    @subscriptions.add @subscribeTo @ignoreButton, 'click': =>
      resolve([])
      @detach()

    @subscriptions.add @subscribeTo @dropPathsButton, 'click': =>
      resolve(['*'])
      @detach()

    @subscriptions.add @subscribeTo @addIgnoreRuleButton, 'click': =>
      @ignoreRulesBlock.style.display = ''
      @prepareList(paths, resolve)

    @subscriptions.add @ignoreRulesEditor.onDidStopChanging =>
      @updateList(@getRules())

    @subscriptions.add @subscribeTo @validatePathsButton, 'click': =>
      resolve(@getRules())
      @detach()

  getRules: ->
    @ignoreRulesEditor.getText().split(',')
    .map (s) -> s.replace /^\s+|\s+$/g, ''
    .filter (s) -> s.length > 0

  detachedCallback: ->
    @subscriptions.dispose()

  prepareList: (paths, resolve) ->
    @validatePathsButton.style.display = ''
    @addIgnoreRuleButton.style.display = 'none'

    html = ''

    for p in paths
      html += """
      <li class='active' data-path='#{p}'>#{atom.project.relativize p}</li>
      """

    @list.innerHTML = html

  updateList: (ignoreRules) ->
    matchRules = (p) ->
      return false for source in ignoreRules when minimatch(p, source, matchBase: true, dot: true)
      return true

    Array::forEach.call @list.children, (child) ->
      child.classList.toggle('active', matchRules(child.dataset.path))

  detach: ->
    @parentNode?.removeChild(this)

module.exports = SourcesPopupElement =
document.registerElement 'pigments-sources-popup', {
  prototype: SourcesPopupElement.prototype
}
