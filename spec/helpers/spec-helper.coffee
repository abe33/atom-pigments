registry = require '../../lib/color-expressions'

beforeEach ->
  registry.removeExpression('variables')

afterEach ->
  registry.removeExpression('variables')
