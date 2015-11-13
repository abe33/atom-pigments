registry = require '../../lib/color-expressions'
Pigments = require '../../lib/pigments'

beforeEach ->
  Pigments.loadDeserializersAndRegisterViews()
  registry.removeExpression('pigments:variables')

afterEach ->
  registry.removeExpression('pigments:variables')
