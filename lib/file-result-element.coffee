_ = require 'underscore-plus'
fs = require 'fs-plus'
path = require 'path'
{CompositeDisposable} = require 'atom'
{SpacePenDSL, EventsDelegation} = require 'atom-utils'
ColorResultElement = require './color-result-element'

module.exports =
class FileResultElement extends HTMLElement
  SpacePenDSL.includeInto(this)
  EventsDelegation.includeInto(this)

  @content: ->
    @div class: 'path list-nested-item', outlet: 'listItem', =>
      @div outlet: 'pathDetails', class: 'path-details list-item', =>
        @span class: 'disclosure-arrow'
        @span outlet: 'icon', class: 'icon icon-file-text'
        @span outlet: 'pathName', class: 'path-name bright'
        @span outlet: 'description', class: 'path-match-number', style: 'display: none'

      @ul outlet: 'matches', class: 'matches list-tree'

  createdCallback: ->
    @subscriptions = new CompositeDisposable

  detachedCallback: ->
    @subscriptions.dispose()

  setModel: (fileResult) ->
    {filePath} = fileResult
    fileBasename = path.basename(filePath)

    @isExpanded = true
    @icon.dataset.name = fileBasename
    @listItem.dataset.path = _.escapeAttribute(filePath)
    @pathName.textContent = filePath.replace(///
      (#{_.escapeRegExp atom.project.getPaths().join('|')})
      #{_.escapeRegExp path.sep}
    ///, '')

    @renderResults(fileResult)
    @subscriptions.add @subscribeTo @pathDetails,
      click: => @expand(not @isExpanded)

  renderResults: ({filePath, matches}) ->
    @description.style.display = ''
    @description.textContent = "(#{matches?.length})"

    for match in matches
      colorResultElement = new ColorResultElement
      colorResultElement.setModel(match)

      @matches.appendChild colorResultElement

  expand: (expanded) ->
    # expand or collapse the list
    if expanded
      @classList.remove('collapsed')

      if @classList.contains('selected')
        @classList.remove('selected')
        firstResult = @querySelector('.search-result:first')
        firstResult.classList.add('selected')
        #
        # # scroll to the proper place
        # resultView = firstResult.closest('.results-view').view()
        # resultView.scrollTop = firstResult.offsetTop

    else
      @classList.add('collapsed')

      selected = @querySelector('.selected')
      if selected?
        selected.classList.remove('selected')
        @classList.add('selected')

        resultView = @closest('.results-view').view()
        resultView.scrollTo(this)

      selectedItem = @querySelector('.selected')

    @isExpanded = expanded

  confirm: ->
    @expand(not @isExpanded)

module.exports = FileResultElement =
document.registerElement 'pigments-file-result', {
  prototype: FileResultElement.prototype
}
