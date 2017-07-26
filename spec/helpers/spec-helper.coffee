registry = require '../../lib/color-expressions'
Pigments = require '../../lib/pigments'

deserializers =
  Palette: 'deserializePalette'
  ColorSearch: 'deserializeColorSearch'
  ColorProject: 'deserializeColorProject'
  ColorProjectElement: 'deserializeColorProjectElement'
  VariablesCollection: 'deserializeVariablesCollection'

beforeEach ->
  atom.config.set('pigments.markerType', 'native-background')
  atom.views.addViewProvider(Pigments.pigmentsViewProvider)

  for k,v of deserializers
    atom.deserializers.add name: k, deserialize: Pigments[v]

  registry.removeExpression('pigments:variables')

  jasmineContent = document.body.querySelector('#jasmine-content')
  jasmineContent.style.width = '100%'
  jasmineContent.style.height = '100%'

afterEach ->
  registry.removeExpression('pigments:variables')
