[![Build Status](https://travis-ci.org/abe33/atom-pigments.svg?branch=master)](https://travis-ci.org/abe33/atom-pigments)

## <img src='https://cdn.rawgit.com/abe33/atom-pigments/master/resources/logo.svg' width='320' height='80'>

A package to display colors in project and files:

![Screenshot](https://github.com/abe33/atom-pigments/blob/master/resources/pigments.gif?raw=true)

Pigments will scan source files in your project directories looking for colors and will build a palette with all of them. Then for each opened file, it will use the palette to evaluate the value of a given color. The legible source paths can be defined through various settings either at the global or per project level. **By default colors in every file will be highlighted, to limit the display of colors to the desired filetype only please see the [Defining Where Pigments Applies](#defining-where-pigments-applies) below.**

Pigments supports out of the box most of the color transformations functions and expressions of the three biggest CSS pre-processors out there, namely LESS, Sass and Stylus. However, it doesn't mean pigments is able to parse and understand all of these languages constructs. For the moment, Pigments' aim is to support the widest range of usage, even if it implies reducing its ability to parse certain complex constructs. You can refer to the [parser specs](https://github.com/abe33/atom-pigments/blob/master/spec/color-parser-spec.coffee) for an exhaustive list of the supported expressions.

## Install

Using `apm`:

```
apm install pigments
```

Or search for `pigments` in Atom settings view.

## Defining Where Pigments Applies

By default, Pigments will highlight every color in every file, but you can limit that using the two settings [`Supported Filetypes`](#supported-filetypes) and [`Ignored Scopes`](#ignored-scopes).

The first setting allow you to specify the list of extensions where pigments will apply. For instance, by using the values `css, less`, colors will be visible only in CSS and Less files.

The second setting takes an array of regular expression strings used to exclude colors in specific scopes (like comments or strings). You can find the scope that applies at the cursor position with the `Editor: Log Cursor Scope` command (<kbd>cmd-alt-p</kbd> or <kbd>ctrl-alt-shift-p</kbd>).

![get scope](https://github.com/abe33/atom-pigments/blob/master/resources/get-scope.gif?raw=true)

## Defaults File

Pigments is able to follow variables uses up to a certain point, if a color refers to several variables whose values can't be evaluated (because they use unsupported language-specific features) the color will be flagged as invalid and not displayed. This can be problematic when it happens on the core components of a complex palette.

To solve that issue, you can define a *defaults file* named `.pigments` at the root of a project directory and you can put in it all the variables declarations to use if a value from the sources files can't be evaluated.

This can also be used when your project core palette is dynamically defined so that pigments can evaluate properly the rest of the project colors.

## Commands

**Note:** Pigments doesn't define any keybindings for the provided commands, instead it'll let you define your own keybindings.

### Pigments: Show Palette

You can display the project's palette through the `Pigments: Show Palette` command from the command palette:

![Screenshot](https://github.com/abe33/atom-pigments/blob/master/resources/palette.gif?raw=true)

The project palette is made of all the colors that are affected to a variable, which means it won't display hardcoded colors affected to a CSS property. If you want to find every color used in a project, including the hardcoded colors in CSS files, use the `Pigments: Find Colors` instead.

Patterns for Less, Sass, Scss and Stylus variables are currently supported, which includes:

```stylus
my-var = #123456 // stylus
```
```sass
$my-var: #123456 // sass
$my-var: #123456; // scss
```
```css
@my-var: #123456; /* less */
```

As with every command, this command can be triggered using the keyboard by defining a keybinding like this:

```coffee
'atom-workspace':
  'alt-shift-p': 'pigments:show-palette'
```

### Pigments: Find Colors

You can search for all colors in your project using the `Pigments: Find Colors` command from the command palette:

![Screenshot](https://github.com/abe33/atom-pigments/blob/master/resources/search.gif?raw=true)

The results will include colors declared in variables, places where the color variables are used as well as hardcoded color values in every file that matches one of the patterns defined in both `pigments.sourceNames` and `pigments.extendedSearchNames` settings.

By default this includes:

```
**/*.css
**/*.less
**/*.scss
**/*.sass
**/*.styl
**/*.stylus
```

This command can be triggered using the keyboard by defining a keybinding like this:

```coffee
'atom-workspace':
  'alt-shift-f': 'pigments:find-colors'
```

### Pigments: Convert To *

It evaluates and replace a color by the corresponding notation.
Accessible from the command palette or by right clicking on a color.

![pigments-conversion](https://github.com/abe33/atom-pigments/blob/master/resources/context-menu-conversion.gif?raw=true)

These commands can be triggered using the keyboard by defining a keybinding like this:

```coffee
'atom-workspace':
  'alt-shift-h': 'pigments:convert-to-hex'
  'alt-shift-g': 'pigments:convert-to-rgb'
  'alt-shift-j': 'pigments:convert-to-rgba'
  'alt-shift-k': 'pigments:convert-to-hsl'
  'alt-shift-l': 'pigments:convert-to-hsla'
```

When triggered from the command palette or from the keyboard, the conversion will operate on every cursor positioned on color markers.

### Pigments: Project Settings

Each Pigments project has its own set of settings that can extend or replace the global configuration. These settings are available through the `pigments:project-settings` command:

![pigments-conversion](https://github.com/abe33/atom-pigments/blob/master/resources/project-settings.png?raw=true)

The `Source Names`, `Ignored Names`, `Ignored Scopes` and `Extended Search Names` fields all match a global configuration. When defined the project will use both the global config and the one of the current project, except when the `Ignore Global` checkbox is checked.

The `Include Atom Themes Stylesheets` setting is specific to the project and can't be defined globally. When enabled, it'll add all the public themes variables in the current project palette:

![pigments-conversion](https://github.com/abe33/atom-pigments/blob/master/resources/project-settings.gif?raw=true)

**Note that it won't add all the variables defined in the less files of the syntax and ui themes, only the ones that must be present as defined in the [themes documentation](https://atom.io/docs/latest/hacking-atom-creating-a-theme).**

**This feature is still quite experimental at this stage.**

### Pigments: Reload

This command will force a reload of all variables in the project, this can be useful when the serialized state of the plugin contains invalid data and you want to get rid of them without having to touch to the content of the `.atom/storage` directory.

This command can be triggered using the keyboard by defining a keybinding like this:

```coffee
'atom-workspace':
  'alt-shift-r': 'pigments:reload'
```

## Settings

### Source Names

An array of glob patterns of the files to use as source for the project's variables and colors.

* Key: `pigments.sourceNames`
* Default: `['**/*.styl', '**/*.stylus', '**/*.less', '**/*.sass', '**/*.scss']`

### Ignored Names

An array of glob patterns of the files to ignore as source files for the project's variables and colors.

* Key: `pigments.ignoredNames`
* Default: `['node_modules/*']`

### Extended Search Names

An array of glob patterns of files to include in the `Pigments: Find Colors` scanning process.

* Key: `pigments.extendedSearchNames`
* Default: `['**/*.css']`

### Supported Filetypes

An array of file extensions where colors will be highlighted. If the wildcard `*` is present in this array then colors in every file will be highlighted.

* Key: `pigments.supportedFiletypes`
* Default: `['*']`

### Extended Filetypes For Color Words

An array of file extensions where color values such as `red`, `azure` or `whitesmoke` will be highlighted. By default CSS and CSS pre-processors files are supported.

* Key: `pigments.extendedFiletypesForColorWords`
* Default: `[]`

### Ignored Scopes

An array of regular expressions strings to match scopes to ignore when rendering colors in a text editor.

For instance, if you want to ignore colors in comments and strings in your source files, use the following value:

```
\.comment, \.string
```

As you can notice, the `.` character in scopes are escaped. This is due to the fact that this setting uses javascript `RegExp` to test the token's scope and the `.` is used to match against any character.

For instance, to ignore colors in html attributes you can use the following expression:

```
\.text\.html(.*)\.string
```

Note the `(.*)` in the middle of the expression. It'll ensure that we're searching for the `.string` scope in the `.text.html` grammar even if there's other scope between them by catching any character between the two classnames.

To find which scope is applied at a given position in a buffer you can use the `editor:log-cursor-scope` command. From that you'll be able to determine what expression to use to match the scope.

* Key: `pigments.ignoredScopes`
* Default: `[]`

### Autocomplete Scopes

The autocomplete provider will only complete color names in editors whose scope is present in this list.

* Key: `pigments.autocompleteScopes`
* Default: `['.source.css', '.source.css.less', '.source.sass', '.source.css.scss', '.source.stylus']`

### Extend Autocomplete To Variables

When enabled, the autocomplete provider will also provides completion for non-color variables.

* Key: `pigments.extendAutocompleteToVariables`
* Default: `false`

### Extend Autocomplete To Color Value

When enabled, the autocomplete provider will also provides color value.

* Key: `pigments.extendAutocompleteToColorValue`
* Default: `false`

### Traverse Into Symlink Directories

Whether to traverse symlinked directories to find source files or not.

* Key: `pigments.traverseIntoSymlinkDirectories`
* Default: `false`

### Ignore VCS Ignored Paths

When this setting is enabled, every file that are ignored by the VCS will also be ignored in Pigments. That means they'll be excluded when searching for colors and when building the project palette.

* Key: `pigments.ignoreVcsIgnoredPaths`
* Default: `true`

### Marker Type

Defines the render mode of color markers. The possible values are:

<table>
  <tr>
    <th>background</th>
    <th>outline</th>
    <th>underline</th>
  </tr>
  <tr>
    <td>
      <img src='https://github.com/abe33/atom-pigments/blob/master/resources/background-renderer.png?raw=true'/>
    </td>
    <td>
      <img src='https://github.com/abe33/atom-pigments/blob/master/resources/outline-renderer.png?raw=true'/>
    </td>
    <td>
      <img src='https://github.com/abe33/atom-pigments/blob/master/resources/underline-renderer.png?raw=true'/>
    </td>
  </tr>
  <tr>
    <th>dot</th>
    <th>square-dot</th>
    <th>gutter</th>
  </tr>
  <tr>
    <td>
      <img src='https://github.com/abe33/atom-pigments/blob/master/resources/dot-renderer.png?raw=true'/>
    </td>
    <td>
      <img src='https://github.com/abe33/atom-pigments/blob/master/resources/square-dot-renderer.png?raw=true'/>
    </td>
    <td>
      <img src='https://github.com/abe33/atom-pigments/blob/master/resources/gutter-color.png?raw=true'/>
    </td>
  </tr>
</table>

* Key: `pigments.markerType`
* Default: `'background'`

### Sort Palette Colors

The type of sorting applied to the colors in the palette view. It can be changed directly from the palette view.

* Key: `pigments.sortPaletteColors`
* Default: `'none'`

### Group Palette Colors

Defines how the colors are grouped together in the palette view. It can be changed directly from the palette view.

* Key: `pigments.groupPaletteColors`
* Default: `'none'`

### Merge Duplicates

Defines whether to merge colors duplicates together as a single result in the palette view. It can be changed directly from the palette view.

* Key: `pigments.mergeDuplicates`
* Default: `false`

### Delay Before Scan

Pigments rescans the text buffer once you stopped editing it, however as the process can be sometime expensive, it'll apply an extra delay after the dispatch of the `did-stop-changing` event before starting the scanning process. This setting define the number of milliseconds to wait after the `did-stop-changing` event before starting to scan the buffer again. If your start typing in the buffer again in this interval, the rescan process will be aborted.

* Key: `pigments.delayBeforeScan`
* Default: `500` (ms)
