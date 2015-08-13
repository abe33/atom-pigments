{TextEditor} = require 'atom'
Color = require '../lib/color'
ColorMarker = require '../lib/color-marker'

describe 'ColorMarker', ->
  [editor, marker, colorMarker, colorMarkerElement, jasmineContent] = []

  beforeEach ->
    editor = new TextEditor({})
    editor.setText("""
    body {
      color: hsva(0, 100%, 100%, 0.5);
      bar: foo;
      foo: bar;
    }
    """)
    marker = editor.markBufferRange [[1,9],[1,33]], type: 'pigments-color'
    color = new Color(255, 0, 0, 0.5)
    text = 'hsva(0, 100%, 100%, 0.5)'

    colorMarker = new ColorMarker({marker, color, text})

  describe '::convertContentToHex', ->
    beforeEach ->
      colorMarker.convertContentToHex()

    it 'replaces the text in the editor by the hexadecimal version', ->
      expect(editor.getText()).toEqual("""
      body {
        color: #ff0000;
        bar: foo;
        foo: bar;
      }
      """)

  describe '::convertContentToRGBA', ->
    beforeEach ->
      colorMarker.convertContentToRGBA()

    it 'replaces the text in the editor by the rgba version', ->
      expect(editor.getText()).toEqual("""
      body {
        color: rgba(255, 0, 0, 0.5);
        bar: foo;
        foo: bar;
      }
      """)

    describe 'when the color alpha is 1', ->
      beforeEach ->
        colorMarker.color.alpha = 1
        colorMarker.convertContentToRGBA()

      it 'replaces the text in the editor by the rgba version', ->
        expect(editor.getText()).toEqual("""
        body {
          color: rgba(255, 0, 0, 1);
          bar: foo;
          foo: bar;
        }
        """)

  describe '::convertContentToRGB', ->
    beforeEach ->
      colorMarker.color.alpha = 1
      colorMarker.convertContentToRGB()

    it 'replaces the text in the editor by the rgba version', ->
      expect(editor.getText()).toEqual("""
      body {
        color: rgb(255, 0, 0);
        bar: foo;
        foo: bar;
      }
      """)

    describe 'when the color alpha is not 1', ->
      beforeEach ->
        colorMarker.convertContentToRGB()

      it 'replaces the text in the editor by the rgba version', ->
        expect(editor.getText()).toEqual("""
        body {
          color: rgb(255, 0, 0);
          bar: foo;
          foo: bar;
        }
        """)
