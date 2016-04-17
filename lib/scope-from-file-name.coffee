path = require 'path'
module.exports = (p) ->
  return 'pigments' if p.match(/\/\.pigments$/)
  path.extname(p)[1..-1]
