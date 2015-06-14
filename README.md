[![Build Status](https://travis-ci.org/abe33/atom-pigments.svg?branch=master)](https://travis-ci.org/abe33/atom-pigments)

![Pigments Logo](https://cdn.rawgit.com/abe33/atom-pigments/master/resources/pigments-logo.svg)

A package to display colors in project and files.

![Screenshot](https://github.com/abe33/atom-pigments/blob/master/resources/pigments.gif?raw=true)

## Install

Using `apm`:

```
apm install pigments
```

Or search for `pigments` in Atom settings view.

## Commands

### Pigments: Show Palette

You can display the project's palette through the `Pigments: Show Palette` command from the command palette:

![Screenshot](https://github.com/abe33/atom-pigments/blob/master/resources/palette.gif?raw=true)

This command can be triggered using the keyboard by defining a keybinding like this:

```coffee
'atom-workspace':
  'alt-shift-p': 'pigments:show-palette'
```

### Pigments: Find Colors

You can search for all colors in every source files using the `Pigments: Find Colors` command from the command palette:

![Screenshot](https://github.com/abe33/atom-pigments/blob/master/resources/search.gif?raw=true)

This command can be triggered using the keyboard by defining a keybinding like this:

```coffee
'atom-workspace':
  'alt-shift-f': 'pigments:find-colors'
```

### Pigments: Reload

This command will force a reload of all variables in the project, this can be useful when the serialized state of the plugin contains invalid data and you want to get rid of them without having to touch to the content of the `.atom/storage` directory.

This command can be triggered using the keyboard by defining a keybinding like this:

```coffee
'atom-workspace':
  'alt-shift-r': 'pigments:reload'
```

### Pigments: Convert To Hexadecimal/Pigments: Convert to RGBA

It evaluates and replace a color by either its hexadecimal notation or rgba notation.
Accessible from the command palette or by right clicking on a color.

![pigments-conversion](https://github.com/abe33/atom-pigments/blob/master/resources/context-menu-conversion.gif?raw=true)

These commands can be triggered using the keyboard by defining a keybinding like this:

```coffee
'atom-workspace':
  'alt-shift-h': 'pigments:convert-to-hex'
  'alt-shift-g': 'pigments:convert-to-rgba'
```

When triggered from the command palette or from the keyboard, the conversion will operate on every cursors positioned on color markers.

## Settings

### Source Names

An array of glob patterns of the files to use as source for the project's variables and colors.

* Key: `pigments.sourceNames`
* Default: `'**/*.styl', '**/*.stylus', '**/*.less', '**/*.sass', '**/*.scss'`

### Ignored Names

An array of glob patterns of the files to ignore as source files for the project's variables and colors.

* Key: `pigments.ignoredNames`
* Default: `['node_modules/*']`

### Ignored Scopes

An array of regular expressions strings to match scopes to ignore when rendering colors in a text editor.

For instance, if you want to ignore colors in comments and strings in your source files, use the following value:

```
\.comment, \.string
```

* Key: `pigments.ignoredScopes`
* Default: `[]`

### Autocomplete Scopes

The autocomplete provider will only complete color names in editors whose scope is present in this list.

* Key: `pigments.autocompleteScopes`
* Default: `'.source.css', '.source.css.less', '.source.sass', '.source.css.scss', '.source.stylus'`

### Extend Autocomplete To Variables

When enabled, the autocomplete provider will also provides completion for non-color variables.

* Key: `pigments.extendAutocompleteToVariables`
* Default: `false`

### Traverse Into Symlink Directories

Whether to traverse symlinked directories to find source files or not.

* Key: `pigments.traverseIntoSymlinkDirectories`
* Default: `false`

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
  </tr>
  <tr>
    <td>
      <img src='https://github.com/abe33/atom-pigments/blob/master/resources/dot-renderer.png?raw=true'/>
    </td>
    <td>
      <img src='https://github.com/abe33/atom-pigments/blob/master/resources/square-dot-renderer.png?raw=true'/>
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
