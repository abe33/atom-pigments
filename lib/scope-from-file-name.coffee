path = require 'path'
module.exports = (p) ->
  return unless p?
  if p.match(/\/\.pigments$/) then 'pigments' else path.extname(p)[1..-1]
