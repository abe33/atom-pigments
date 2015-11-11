## ColorContext API

A `ColorContext` main responsibility is to resolve values when parsing a color in the context of a Pigments project.

For instance, let's take the following Less expression:

```css
color: @fadeout(@background-color-info, 20%);
```

When parsing this expression we'll need to retrieve the value of the `@background-color-info` variable.

In the handler function for the `fadeout` function we'll do something like this:

```js
[, color, amount] = match;

amount = context.readPercent(amount);
color = context.readColor(color);

// returning and marking the color as invalid if there's
// no base color
if(context.isInvalid(color)) return this.invalid = true;

// computing the resulting color take place here
```

In the example above, the `readPercent` and `readColor` methods are used to retrieve the proper value without caring whether the initial value was a literal value or a reference to a variable. The context will resolve that for us. And it will also keep track of all the variables used during the parsing so that Pigments can build the dependency tree for the resulting color.

As expression handler functions can't rely on their scope, the context will also provide some utilities to simplify the works of parsing complex expressions.

### Value Retrieval Methods

#### readColor

#### readInt

#### readFloat

#### readPercent

#### readIntOrPercent

#### readFloatOrPercent


### Utility Methods

#### split

#### clamp

#### clampInt

#### isInvalid

#### readParam

#### contrast

#### mixColors


### Properties

#### Color

#### SVGColors

#### BlendModes

#### int

#### float

#### percent

#### optionalPercent

#### intOrPercent

#### floatOrPercent

#### comma

#### notQuote

#### hexadecimal

#### ps (start parenthesis)

#### pe (end parenthesis)

#### variablesRE

#### namePrefixes
