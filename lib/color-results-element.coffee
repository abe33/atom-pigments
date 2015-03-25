{CompositeDisposable} = require 'atom'
{SpacePenDSL, EventsDelegation} = require 'atom-utils'
FileResultElement = require './file-result-element'

module.exports =
class ColorResultsElement extends HTMLElement
  SpacePenDSL.includeInto(this)
  EventsDelegation.includeInto(this)

  @content: ->
    @tag 'atom-panel', outlet: 'pane', class: 'preview-pane pane-item', =>
      @div class: 'panel-heading', =>
        @span outlet: 'previewCount', class: 'preview-count inline-block'
        @div outlet: 'loadingMessage', class: 'inline-block', =>
          @div class: 'loading loading-spinner-tiny inline-block'
          @div outlet: 'searchedCountBlock', class: 'inline-block', =>
            @span outlet: 'searchedCount', class: 'searched-count'
            @span ' paths searched'

      @div outlet: 'resultsList', class: 'search-colors-results results-view list-tree focusable-panel has-collapsable-children', tabindex: -1

  createdCallback: ->
    @subscriptions = new CompositeDisposable

    @files = 0
    @colors = 0

    @loadingMessage.style.display = 'none'

  setModel: (@colorSearch) ->
    @subscriptions.add @colorSearch.onDidFindMatches (result) =>
      @addFileResult(result)

    @subscriptions.add @colorSearch.onDidCompleteSearch =>
      @searchComplete()

    @colorSearch.search()

  getTitle: -> 'Pigments Find Results'

  getURI: -> 'pigments://search'

  addFileResult: (result) ->
    @files += 1
    @colors += result.matches.length

    fileResultElement = new FileResultElement
    fileResultElement.setModel(result)

    @resultsList.appendChild(fileResultElement)
    @updateMessage()

  searchComplete: ->
    @udpateMessage()

    if @colors is 0
      @pane.classList.add 'no-results'
      @pane.appendChild """
      <ul class='centered background-message no-results-overlay'>
        <li>No Results</li>
      </ul>
      """

  updateMessage: ->
    filesString = if @files is 1 then 'file' else 'files'

    @previewCount.innerHTML = if @colors > 0
      """
      <span class='text-info'>
        #{@colors} colors
      </span>
      found in
      <span class='text-info'>
        #{@files} #{filesString}
      </span>
      """
    else
      "No colors found in #{@files} #{filesString}"

module.exports = ColorResultsElement =
document.registerElement 'pigments-color-results', {
  prototype: ColorResultsElement.prototype
}

ColorResultsElement.registerViewProvider = (modelClass) ->
  atom.views.addViewProvider modelClass, (model) ->
    element = new ColorResultsElement
    element.setModel(model)
    element
