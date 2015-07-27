{findClosingIndex, split} = require '../lib/utils'

describe 'split', ->
  it 'does not fail when there is parenthesis after', ->
    string = "a,)("

    res = split(string)

    expect(res).toEqual(['a',''])
