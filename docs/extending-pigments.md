## Extending Pigments

A package can extends Pigments definitions using two consumer services:  `pigments.expressions.colors` and `pigments.expressions.variables`. These two services allow to register new color and variable expressions respectively.

### Adding Color Expressions

First, you'll need to define a service provider in your `package.json` file:

```json
"providedServices": {
  "pigments.expressions.colors": {
    "versions": {
      "1.0.0": "provideColorExpressions"
    }
  }
}
```

Then in the `provideColorExpressions` function you'll need to return an object as follow:

```js
'use babel';

export default {
  // ...

  provideColorExpressions: => {
    return {
      name: 'my-custom-color-expression',
      regexpString: 'color\\[[a-fA-F0-9]{6}\\]', // match color[FFC6ae]
      scopes: ['my-scope'],
      handle: function myHandle (match, expression, context) {
        let hexString = match[1];

        this.hex = hexString;
      }
    };
  },

  // ...
};
```

In the example above the provider only provides one expression. To return an array of expressions you can do as follow:

```js
'use babel';

export default {
  // ...

  provideColorExpressions: => {
    return {
      expressions: [
        {
          name: 'my-custom-color-expression',
          regexpString: 'color\\[([a-fA-F0-9]{6})\\]', // match color[FFC6ae]
          scopes: ['my-scope'],
          handle: function myHandle (match, expression, context) {
            let hexString = match[1];

            this.hex = hexString;
          }
        },{
          name: 'my-custom-color-expression-with-alpha',
          regexpString: 'color\\[([a-fA-F0-9]{6}),\\s*\\d+\\]', // match color[FFC6ae, 75]
          scopes: ['my-scope'],
          handle: function myHandle (match, expression, context) {
            let hexString = match[1];
            let alpha = Number(match[2]);

            this.hex = hexString;
            this.alpha = alpha;
          }
        }
      ]
    };
  },

  // ...
};
```

A color expression can have the following properties:

- `name` - **Mandatory** - A unique name to identify this expression. The name can contains spaces and any special character. One way to ensure its uniqueness is to prefix the name with your package name, such as in `pigments:css_hexa_6`.
- `regexpString` - **Mandatory** - The regular expression string to use to match the color expression. This expression will be used both when searching for color patterns in a file and when parsing the color. When used to search patterns in a file all the expressions `regexpString` will be concatenated into a single expression according to their `priority`. It means it should contains neither start nor end string anchor (`^` or `$`).
- `handle` - **Mandatory** - The function invoked when parsing a string matched by `regexpString`. The function will be called with a new `Color` instance as `this` and will receive the following arguments:
  - `match` - The result match returned by running `regexpString` against a matched expression.
  - `expression` - The string expression that was matched by the `regexpString`.
  - `context` - A `ColorContext` instance you can use to parse the color (see the [ColorContext API documentation](./color-context-api.md)).

  **It's important to note that the handle function must not rely on the scope in which it is declared.** This is because the expression handler will be serialized using the `toString` method and passed to a child process to be then evaluated in a sandboxed environment. It allows to perform all the searches on second thread without locking the UI.
- `scopes`- An array of string of the file extensions supported by this expression. You can use the wildcard `*` to apply this expression to any file.
- `priority` - A number that indicates the priority of the expression in comparison to the other expressions in the registry. The higher the value the sooner the expression will appear in the global search regular expression.


### Adding Variable Expressions

First, you'll need to define a service provider in your `package.json` file:

```json
"providedServices": {
  "pigments.expressions.variables": {
    "versions": {
      "1.0.0": "provideVariableExpressions"
    }
  }
}
```

Then in the `provideVariableExpressions` function you'll need to return an object as follow:

```js
'use babel';

export default {
  // ...

  provideVariableExpressions: => {
    return {
      name: 'my-custom-variable-expression',
      regexpString: '\[\[(\w+):([^\]]+)\]\]', // match [[red:250,0,0,0]]
      scopes: ['my-scope']
    };
  },

  // ...
};
```

In the example above the provider only provides one expression. To return an array of expressions you can do as follow:

```js
'use babel';

export default {
  // ...

  provideVariableExpressions: => {
    return
    {
      expressions: [
        {
          name: 'my-custom-variable-expression',
          regexpString: '\[\[(\w+):([^\]]+)\]\]', // match [[red:250,0,0,0]]
          scopes: ['my-scope']
        },
        // ...
      ]
    };
  },

  // ...
};
```

A variable expression can have the following properties:

- `name` - **Mandatory** - A unique name to identify this expression. The name can contains spaces and any special character. One way to ensure its uniqueness is to prefix the name with your package name, such as in `pigments:css_hexa_6`.
- `regexpString` - **Mandatory** - The regular expression string to use to match the variable expression. This expression will be used both when searching for variable patterns in a file and when parsing the variable. When used to search patterns in a file all the expressions `regexpString` will be concatenated into a single expression according to their `priority`. It means it should contains neither start nor end string anchor (`^` or `$`). **The expression should only contains two capturing group, the first for the variable name, the second for the variable value.**
- `handle` - An optional function that you can use to handle the parsing in the case of a complex definition context that can't be parsed with a regext (which is the case of [stylus hashes](https://github.com/abe33/atom-pigments/blob/master/lib/variable-expressions.coffee#L17-L62) for instance). The function takes two arguments:
  - `match` - The result match returned by running `regexpString` against a matched expression.
  - `solver` - An object with various methods you can use to creates variables while parsing a string. The object has the following methods:
    - `endParsing (end)` - Terminates the parsing successfully, in that case all created variables will transferred to the project.
    - `abortParsing ()` - Aborts the parsing, preventing any created variables from being passed to the project.
    - `appendResult ([name, value, startIndex, endIndex])` - Registers a variable result. It takes an array with the name of the variable, its name, and the start and end index of the match in the initially matched string. These indices will automatically have an offset applied to reflect their position in the file.
- `scopes`- An array of string of the file extensions supported by this expression. You can use the wildcard `*` to apply this expression to any file.
- `priority` - A number that indicates the priority of the expression in comparison to the other expressions in the registry. The higher the value the sooner the expression will appear in the global search regular expression.
