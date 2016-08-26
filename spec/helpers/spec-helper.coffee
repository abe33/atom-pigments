registry = require '../../lib/color-expressions'
Pigments = require '../../lib/pigments'

deserializers =
  Palette: 'deserializePalette'
  ColorSearch: 'deserializeColorSearch'
  ColorProject: 'deserializeColorProject'
  ColorProjectElement: 'deserializeColorProjectElement'
  VariablesCollection: 'deserializeVariablesCollection'

beforeEach ->
  atom.views.addViewProvider(Pigments.pigmentsViewProvider)

  for k,v of deserializers
    atom.deserializers.add name: k, deserialize: Pigments[v]

  registry.removeExpression('pigments:variables')

afterEach ->
  registry.removeExpression('pigments:variables')
