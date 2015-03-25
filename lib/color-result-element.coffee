{Range, CompositeDisposable} = require 'atom'
{SpacePenDSL, EventsDelegation} = require 'atom-utils'

LeadingWhitespace = /^\s+/
removeLeadingWhitespace = (string) -> string.replace(LeadingWhitespace, '')

module.exports =
class ColorResultElement extends HTMLElement
  SpacePenDSL.includeInto(this)
  EventsDelegation.includeInto(this)

  @content: ->
    @li class: 'search-result list-item', =>
      @span outlet: 'lineNumber', class: 'line-number text-subtle'
      @span class: 'preview', outlet: 'preview', =>

  createdCallback: ->
    @subscriptions = new CompositeDisposable

  setModel: (match) ->
    textColor = if match.color.luma > 0.43
      'black'
    else
      'white'

    {@filePath, @range} = match

    range = Range.fromObject(@range)
    matchStart = range.start.column - match.lineTextOffset
    matchEnd = range.end.column - match.lineTextOffset
    prefix = removeLeadingWhitespace(match.lineText[0...matchStart])
    suffix = match.lineText[matchEnd..]

    @lineNumber.textContent = range.start.row + 1
    @preview.innerHTML = """
    #{prefix}
    <span class='match color-match' style='background: #{match.color.toCSS()}; color: #{textColor}'>
      #{match.matchText}
    </span>
    #{suffix}
    """

    if fontFamily = atom.config.get('editor.fontFamily')
      @preview.style.fontFamily = fontFamily

    @subscriptions.add @subscribeTo this,
      click: => @confirm()

  confirm: ->
    atom.workspaceView.open(@filePath, split: 'left').then (editor) =>
      editor.setSelectedBufferRange(@range, autoscroll: true)

module.exports = ColorResultElement =
document.registerElement 'pigments-color-result', {
  prototype: ColorResultElement.prototype
}
