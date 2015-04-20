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

## Settings

### Source Names

An array of glob patterns of the files to use as source for the project's variables and colors.

* Key: `pigments.sourceNames`
* Default: `'**/*.styl', '**/*.stylus', '**/*.less', '**/*.sass', '**/*.scss'`

### Ignored Names

An array of glob patterns of the files to ignore as source files for the project's variables and colors.

* Key: `pigments.ignoredNames`
* Default: `[]`

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
* Default: `true`

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
    <th>dot</th>
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
    <td>
      <img src='https://github.com/abe33/atom-pigments/blob/master/resources/dot-renderer.png?raw=true'/>
    </td>
  </tr>
</table>

* Key: `pigments.markerType`
* Default: `'background'`

### Sort Palette Colors

* Key: `pigments.sortPaletteColors`
* Default: `'none'`

### Group Palette Colors

* Key: `pigments.groupPaletteColors`
* Default: `'none'`

### Merge Duplicates

* Key: `pigments.mergeDuplicates`
* Default: `false`
