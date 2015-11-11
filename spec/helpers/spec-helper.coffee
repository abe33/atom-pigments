registry = require '../../lib/color-expressions'

beforeEach ->
  registry.removeExpression('pigments:variables')

afterEach ->
  registry.removeExpression('pigments:variables')
