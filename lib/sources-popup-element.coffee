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
            Pigments has found <span class='text-warning'>0</span> files that
            can contains variables and the warning threshold is set to
            <span class='text-warning'>#{atom.config.get 'pigments.sourcesWarningThreshold'}</span>.
            All theses files aren't always necessary and can lead to performances
            issues so it's sometime better ignore some paths.
          """

        @p class: 'text-warning', =>
          @raw """
            By choosing <kbd>Ignore Alert</kbd> the initialization will proceed
            as usual with all the project paths. By choosing
            <kbd>Drop Found Paths</kbd> a new ignore rule with value
            <kbd>'*'</kbd> will be added to the project ignore rules.
          """

        @span class: 'text-warning', =>
          @raw """
          The <kbd>Set Ignore Rules</kbd> option will allow you to define
          pigments specific patterns for ignored files. Use a comma to separate
          the different patterns.
          """

      @div outlet: 'ignoreRulesBlock', class: 'block', style: 'display: none', =>
        @tag 'atom-text-editor', mini: true, outlet: 'ignoreRulesEditorView', 'placeholder-text': 'Use glob-like pattern to filter the paths list below'
        @div class: 'select-list', =>
          @ol outlet: 'list', class: 'list-group mark-active'


      @div class: 'block', =>
        @button outlet: 'addIgnoreRuleButton', class: 'btn', 'Set Ignore Rules'
        @button outlet: 'validatePathsButton', class: 'btn', 'Validate Paths'

        @div class: 'btn-group pull-right', =>
          @button outlet: 'ignoreButton', class: 'btn', 'Ignore Alert'
          @button outlet: 'dropPathsButton', class: 'btn', 'Drop Found Paths'

  initialize: ({paths, resolve, reject}) ->
    @foundFiles = @querySelector('p .text-warning')
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
