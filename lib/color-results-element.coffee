_ = require 'underscore-plus'
fs = require 'fs-plus'
path = require 'path'
{Range, CompositeDisposable} = require 'atom'
{SpacePenDSL, EventsDelegation, AncestorsMethods} = require 'atom-utils'

removeLeadingWhitespace = (string) -> string.replace(/^\s+/, '')

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

      @ol outlet: 'resultsList', class: 'search-colors-results results-view list-tree focusable-panel has-collapsable-children', tabindex: -1

  createdCallback: ->
    @subscriptions = new CompositeDisposable

    @files = 0
    @colors = 0

    @loadingMessage.style.display = 'none'

    @subscriptions.add @subscribeTo this, '.list-nested-item > .list-item',
      click: (e) ->
        e.stopPropagation()
        fileItem = AncestorsMethods.parents(e.target,'.list-nested-item')[0]
        fileItem.classList.toggle('collapsed')

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

    @resultsList.innerHTML += @createFileResult(result)
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

  createFileResult: (fileResult) ->
    {filePath,matches} = fileResult
    fileBasename = path.basename(filePath)

    pathAttribute = _.escapeAttribute(filePath)
    pathName = atom.project.relativize(filePath)

    """
    <li class="path list-nested-item" data-path="#{pathAttribute}">
      <div class="path-details list-item">
        <span class="disclosure-arrow"></span>
        <span class="icon icon-file-text" data-name="#{fileBasename}"></span>
        <span class="path-name bright">#{pathName}</span>
        <span class="path-match-number">(#{matches.length + 1})</span></div>
      </div>
      <ul class="matches list-tree">
        #{matches.map((match) => @createMatchResult match).join('')}
      </ul>
    </li>"""

  createMatchResult: (match) ->
    textColor = if match.color.luma > 0.43
      'black'
    else
      'white'

    {filePath, range} = match

    range = Range.fromObject(range)
    matchStart = range.start.column - match.lineTextOffset
    matchEnd = range.end.column - match.lineTextOffset
    prefix = removeLeadingWhitespace(match.lineText[0...matchStart])
    suffix = match.lineText[matchEnd..]
    lineNumber = range.start.row + 1
    style = ''
    style += "background: #{match.color.toCSS()};"
    style += "color: #{textColor};"

    if fontFamily = atom.config.get('editor.fontFamily')
      style += "font-family: #{fontFamily};"

    """
    <li class="search-result list-item">
      <span class="line-number text-subtle">#{lineNumber}</span>
      <span class="preview">
        #{prefix}
        <span class='match color-match' style='#{style}'>
          #{match.matchText}
        </span>
        #{suffix}
      </span>
    </li>
    """


module.exports = ColorResultsElement =
document.registerElement 'pigments-color-results', {
  prototype: ColorResultsElement.prototype
}

ColorResultsElement.registerViewProvider = (modelClass) ->
  atom.views.addViewProvider modelClass, (model) ->
    element = new ColorResultsElement
    element.setModel(model)
    element
