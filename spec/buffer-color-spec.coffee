Color = require '../lib/color'
BufferColor = require '../lib/buffer-color'

describe 'BufferColor', ->
  [bufferColor] = []

  beforeEach ->
    bufferColor = new BufferColor
      color: new Color('#ffcc66')
      match: '#ffcc66'
      textRange: [0, 7]
      bufferRange: [[0,0], [0,7]]

  it 'stores the passed-in data', ->
    expect(bufferColor.color).toBeDefined()
    expect(bufferColor.match).toBeDefined()
    expect(bufferColor.textRange).toBeDefined()
    expect(bufferColor.bufferRange).toBeDefined()
