{findClosingIndex, split} = require '../lib/utils'

describe '.split()', ->
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
    ['(,(,(,)', []]
    ['a,(,', ['a']]
    ['a,((),', ['a']]
    ['a,()),', ['a', '()']]
  ]

  tests.forEach ([source, expected]) ->
    it "splits #{jasmine.pp source} as #{jasmine.pp(expected)}", ->
      expect(split(source)).toEqual(expected)

describe '.findClosingIndex()', ->
  tests = [
    ['a(', -1]
    ['a()', 2]
    ['a(((()', -1]
  ]

  tests.forEach ([source, expected]) ->
    it "returs the index of the closing character", ->
      expect(findClosingIndex(source, 2, '(', ')')).toEqual(expected)
