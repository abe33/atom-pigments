{findClosingIndex, split} = require '../lib/utils'

describe 'split', ->
  tests = [
    ['a,b,c', ['a', 'b', 'c']]
    ['a,b(),c', ['a', 'b()', 'c']]
    ['a,b(c)', ['a', 'b(c)']]
    ['a,(b, c)', ['a', '(b,c)']]
    ['a,(b, c())', ['a', '(b,c())']]
    ['a(b, c())', ['a(b,c())']]
    ['a,)(', ['a']]
    ['a(,', []]
    ['(,', []]
    ['a,(,', ['a']]
    ['a,((),', ['a']]
    ['a,()),', ['a', '()']]
  ]

  tests.forEach ([source, expected]) ->
    it "splits #{jasmine.pp source} as #{jasmine.pp(expected)}", ->
      expect(split(source)).toEqual(expected)
