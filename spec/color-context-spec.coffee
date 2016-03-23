
ColorContext = require '../lib/color-context'
ColorParser = require '../lib/color-parser'
registry = require '../lib/color-expressions'

describe 'ColorContext', ->
  [context, parser] = []

  itParses = (expression) ->
    asUndefined: ->
      it "parses '#{expression}' as undefined", ->
        expect(context.getValue(expression)).toBeUndefined()

    asUndefinedColor: ->
      it "parses '#{expression}' as undefined color", ->
        expect(context.readColor(expression)).toBeUndefined()

    asInt: (expected) ->
      it "parses '#{expression}' as an integer with value of #{expected}", ->
        expect(context.readInt(expression)).toEqual(expected)

    asFloat: (expected) ->
      it "parses '#{expression}' as a float with value of #{expected}", ->
        expect(context.readFloat(expression)).toEqual(expected)

    asIntOrPercent: (expected) ->
      it "parses '#{expression}' as an integer or a percentage with value of #{expected}", ->
        expect(context.readIntOrPercent(expression)).toEqual(expected)

    asFloatOrPercent: (expected) ->
      it "parses '#{expression}' as a float or a percentage with value of #{expected}", ->
        expect(context.readFloatOrPercent(expression)).toEqual(expected)

    asColorExpression: (expected) ->
      it "parses '#{expression}' as a color expression", ->
        expect(context.readColorExpression(expression)).toEqual(expected)

    asColor: (expected...) ->
      it "parses '#{expression}' as a color with value of #{jasmine.pp expected}", ->
        expect(context.readColor(expression)).toBeColor(expected...)

    asInvalidColor: (expected...) ->
      it "parses '#{expression}' as an invalid color", ->
        expect(context.readColor(expression)).not.toBeValid()

  describe 'created without any variables', ->
    beforeEach ->
      context = new ColorContext({registry})

    itParses('10').asInt(10)

    itParses('10').asFloat(10)
    itParses('0.5').asFloat(0.5)
    itParses('.5').asFloat(0.5)

    itParses('10').asIntOrPercent(10)
    itParses('10%').asIntOrPercent(26)

    itParses('0.1').asFloatOrPercent(0.1)
    itParses('10%').asFloatOrPercent(0.1)

    itParses('red').asColorExpression('red')

    itParses('red').asColor(255, 0, 0)
    itParses('#ff0000').asColor(255, 0, 0)
    itParses('rgb(255,127,0)').asColor(255, 127, 0)

  describe 'with a variables array', ->
    createVar = (name, value, path) ->
      {value, name, path: path ? '/path/to/file.coffee'}

    createColorVar = (name, value, path) ->
      v = createVar(name, value, path)
      v.isColor = true
      v

    describe 'that contains valid variables', ->
      beforeEach ->
        variables = [
          createVar 'x', '10'
          createVar 'y', '0.1'
          createVar 'z', '10%'
          createColorVar 'c', 'rgb(255,127,0)'
        ]

        colorVariables = variables.filter (v) -> v.isColor

        context = new ColorContext({variables, colorVariables, registry})

      itParses('x').asInt(10)
      itParses('y').asFloat(0.1)
      itParses('z').asIntOrPercent(26)
      itParses('z').asFloatOrPercent(0.1)

      itParses('c').asColorExpression('rgb(255,127,0)')
      itParses('c').asColor(255, 127, 0)

    describe 'that contains alias for named colors', ->
      beforeEach ->
        variables =[
          createColorVar '$text-color', 'white', '/path/to/file.css.sass'
          createColorVar '$background-color', 'black', '/path/to/file.css.sass'
        ]

        colorVariables = variables.filter (v) -> v.isColor

        context = new ColorContext({variables, colorVariables, registry})

      itParses('$text-color').asColor(255,255,255)
      itParses('$background-color').asColor(0,0,0)

    describe 'that contains invalid colors', ->
      beforeEach ->
        variables =[
          createVar '@text-height', '@scale-b-xxl * 1rem'
          createVar '@component-line-height', '@text-height'
          createVar '@list-item-height', '@component-line-height'
        ]

        context = new ColorContext({variables, registry})

      itParses('@list-item-height').asUndefinedColor()

    describe 'that contains circular references', ->
      beforeEach ->
        variables =[
          createVar '@foo', '@bar'
          createVar '@bar', '@baz'
          createVar '@baz', '@foo'
          createVar '@taz', '@taz'
        ]

        context = new ColorContext({variables, registry})

      itParses('@foo').asUndefined()
      itParses('@taz').asUndefined()

    describe 'that contains circular references', ->
      beforeEach ->
        variables =[
          createColorVar '@foo', '@bar'
          createColorVar '@bar', '@baz'
          createColorVar '@baz', '@foo'
          createColorVar '@taz', '@taz'
        ]

        colorVariables = variables.filter (v) -> v.isColor

        context = new ColorContext({variables, colorVariables, registry})

      itParses('@foo').asInvalidColor()
      itParses('@foo').asUndefined()
      itParses('@taz').asUndefined()

    describe 'that contains circular references nested in operations', ->
      beforeEach ->
        variables =[
          createColorVar '@foo', 'complement(@bar)'
          createColorVar '@bar', 'transparentize(@baz, 0.5)'
          createColorVar '@baz', 'darken(@foo, 10%)'
        ]

        colorVariables = variables.filter (v) -> v.isColor

        context = new ColorContext({variables, colorVariables, registry})

      itParses('@foo').asInvalidColor()

  describe 'with variables from a default file', ->
    [projectPath, referenceVariable] = []
    createVar = (name, value, path) ->
      path ?= "#{projectPath}/file.styl"
      {value, name, path}

    createColorVar = (name, value, path) ->
      v = createVar(name, value, path)
      v.isColor = true
      v

    describe 'when there is another valid value', ->
      beforeEach ->
        projectPath = atom.project.getPaths()[0]
        referenceVariable = createVar 'a', 'b', "#{projectPath}/a.styl"

        variables = [
          referenceVariable
          createVar 'b', '10', "#{projectPath}/.pigments"
          createVar 'b', '20', "#{projectPath}/b.styl"
        ]

        colorVariables = variables.filter (v) -> v.isColor

        context = new ColorContext({
          registry
          variables
          colorVariables
          referenceVariable
          rootPaths: [projectPath]
        })

      itParses('a').asInt(20)

    describe 'when there is no another valid value', ->
      beforeEach ->
        projectPath = atom.project.getPaths()[0]
        referenceVariable = createVar 'a', 'b', "#{projectPath}/a.styl"

        variables = [
          referenceVariable
          createVar 'b', '10', "#{projectPath}/.pigments"
          createVar 'b', 'c', "#{projectPath}/b.styl"
        ]

        colorVariables = variables.filter (v) -> v.isColor

        context = new ColorContext({
          registry
          variables
          colorVariables
          referenceVariable
          rootPaths: [projectPath]
        })

      itParses('a').asInt(10)

    describe 'when there is another valid color', ->
      beforeEach ->
        projectPath = atom.project.getPaths()[0]
        referenceVariable = createColorVar 'a', 'b', "#{projectPath}/a.styl"

        variables = [
          referenceVariable
          createColorVar 'b', '#ff0000', "#{projectPath}/.pigments"
          createColorVar 'b', '#0000ff', "#{projectPath}/b.styl"
        ]

        colorVariables = variables.filter (v) -> v.isColor

        context = new ColorContext({
          registry
          variables
          colorVariables
          referenceVariable
          rootPaths: [projectPath]
        })

      itParses('a').asColor(0, 0, 255)

    describe 'when there is no another valid color', ->
      beforeEach ->
        projectPath = atom.project.getPaths()[0]
        referenceVariable = createColorVar 'a', 'b', "#{projectPath}/a.styl"

        variables = [
          referenceVariable
          createColorVar 'b', '#ff0000', "#{projectPath}/.pigments"
          createColorVar 'b', 'c', "#{projectPath}/b.styl"
        ]

        colorVariables = variables.filter (v) -> v.isColor

        context = new ColorContext({
          registry
          variables
          colorVariables
          referenceVariable
          rootPaths: [projectPath]
        })

      itParses('a').asColor(255, 0, 0)

  describe 'with a reference variable', ->
    [projectPath, referenceVariable] = []
    createVar = (name, value, path) ->
      path ?= "#{projectPath}/file.styl"
      {value, name, path}

    createColorVar = (name, value) ->
      v = createVar(name, value)
      v.isColor = true
      v

    describe 'when there is a single root path', ->
      beforeEach ->
        projectPath = atom.project.getPaths()[0]
        referenceVariable = createVar 'a', '10', "#{projectPath}/a.styl"

        variables = [
          referenceVariable
          createVar 'a', '20', "#{projectPath}/b.styl"
        ]

        colorVariables = variables.filter (v) -> v.isColor

        context = new ColorContext({
          registry
          variables
          colorVariables
          referenceVariable
          rootPaths: [projectPath]
        })

      itParses('a').asInt(10)

    describe 'when there are many root paths', ->
      beforeEach ->
        projectPath = atom.project.getPaths()[0]
        referenceVariable = createVar 'a', 'b', "#{projectPath}/a.styl"

        variables = [
          referenceVariable
          createVar 'b', '10', "#{projectPath}/b.styl"
          createVar 'b', '20', "#{projectPath}2/b.styl"
        ]

        colorVariables = variables.filter (v) -> v.isColor

        context = new ColorContext({
          registry
          variables
          colorVariables
          referenceVariable
          rootPaths: [projectPath, "#{projectPath}2"]
        })

      itParses('a').asInt(10)

  describe 'with a reference path', ->
    [projectPath, referenceVariable] = []
    createVar = (name, value, path) ->
      path ?= "#{projectPath}/file.styl"
      {value, name, path}

    createColorVar = (name, value) ->
      v = createVar(name, value)
      v.isColor = true
      v

    describe 'when there is a single root path', ->
      beforeEach ->
        projectPath = atom.project.getPaths()[0]
        referenceVariable = createVar 'a', '10', "#{projectPath}/a.styl"

        variables = [
          referenceVariable
          createVar 'a', '20', "#{projectPath}/b.styl"
        ]

        colorVariables = variables.filter (v) -> v.isColor

        context = new ColorContext({
          registry
          variables
          colorVariables
          referencePath: "#{projectPath}/a.styl"
          rootPaths: [projectPath]
        })

      itParses('a').asInt(10)

    describe 'when there are many root paths', ->
      beforeEach ->
        projectPath = atom.project.getPaths()[0]
        referenceVariable = createVar 'a', 'b', "#{projectPath}/a.styl"

        variables = [
          referenceVariable
          createVar 'b', '10', "#{projectPath}/b.styl"
          createVar 'b', '20', "#{projectPath}2/b.styl"
        ]

        colorVariables = variables.filter (v) -> v.isColor

        context = new ColorContext({
          registry
          variables
          colorVariables
          referencePath: "#{projectPath}/a.styl"
          rootPaths: [projectPath, "#{projectPath}2"]
        })

      itParses('a').asInt(10)
