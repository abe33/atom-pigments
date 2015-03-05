BufferColor = require '../lib/buffer-color'

describe 'BufferColor', ->
  [bufferColor] = []

  beforeEach ->
    bufferColor = new BufferColor

  it 'lives', -> expect(bufferColor).toBeDefined()
