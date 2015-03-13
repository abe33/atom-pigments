{Emitter, CompositeDisposable} = require 'atom'

module.exports =
class ColorBuffer
  constructor: (params={}) ->
    {@editor, @project} = params
    @emitter = new Emitter
    @subscriptions = new CompositeDisposable

    @subscriptions.add @editor.onDidDestroy => @destroy()

  onDidDestroy: (callback) ->
    @emitter.on 'did-destroy', callback

  destroy: ->
    @subscriptions.dispose()
    @emitter.emit 'did-destroy'

  serialize: -> {editorId: editor.id}
