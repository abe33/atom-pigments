
beforeEach ->
  compare = (a,b,p) -> Math.abs(b - a) < (Math.pow(10, -p) / 2)

  @addMatchers
    toBeComponentArrayCloseTo: (arr, precision=0) ->
      notText = if @isNot then " not" else ""
      this.message = => "Expected #{jasmine.pp(@actual)} to#{notText} be an array whose values are close to #{jasmine.pp(arr)} with a precision of #{precision}"

      return false if @actual.length isnt arr.length

      @actual.every (value,i) -> compare(value, arr[i], precision)

    toBeValid: ->
      notText = if @isNot then " not" else ""
      this.message = => "Expected #{jasmine.pp(@actual)} to#{notText} be a valid color"

      @actual.isValid()

    toBeColor: (colorOrRed,green=0,blue=0,alpha=1) ->
      color = switch typeof colorOrRed
        when 'object' then colorOrRed
        when 'number' then {red: colorOrRed, green, blue, alpha}
        when 'string'
          colorOrRed = colorOrRed.replace(/#|0x/, '')
          hex = parseInt(colorOrRed, 16)
          switch colorOrRed.length
            when 8
              alpha = (hex >> 24 & 0xff) / 255
              red = hex >> 16 & 0xff
              green = hex >> 8 & 0xff
              blue = hex & 0xff
            when 6
              red = hex >> 16 & 0xff
              green = hex >> 8 & 0xff
              blue = hex & 0xff
            when 3
              red = (hex >> 8 & 0xf) * 17
              green = (hex >> 4 & 0xf) * 17
              blue = (hex & 0xf) * 17
            else
              red = 0
              green = 0
              blue = 0
              alpha = 1


          {red, green, blue, alpha}
        else
          {red: 0, green: 0, blue: 0, alpha: 1}

      notText = if @isNot then " not" else ""
      this.message = => "Expected #{jasmine.pp(@actual)} to#{notText} be a color equal to #{jasmine.pp(color)}"

      Math.round(@actual.red) is color.red and
      Math.round(@actual.green) is color.green and
      Math.round(@actual.blue) is color.blue and
      compare(@actual.alpha, color.alpha, 1)
