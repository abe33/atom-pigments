async = require 'async'
fs = require 'fs'
path = require 'path'
{GitRepository} = require 'atom'
{Minimatch} = require 'minimatch'

PathsChunkSize = 100

class PathLoader
  constructor:  (@rootPath, config) ->
    {@timestamp, @sourceNames, ignoreVcsIgnores, @traverseSymlinkDirectories, @ignoredNames, @knownPaths} = config

    @knownPaths ?= []
    @paths = []
    @lostPaths = []
    @scannedPaths = []

    @repo = null
    if ignoreVcsIgnores
      repo = GitRepository.open(@rootPath, refreshOnWindowFocus: false)
      @repo = repo if repo?.relativize(path.join(@rootPath, 'test')) is 'test'

  load: (done) ->
    @loadPath @rootPath, =>
      for p in @knownPaths
        if p not in @scannedPaths and p.indexOf(@rootPath) is 0
          @lostPaths.push(p)

      @flushPaths()
      @repo?.destroy()
      done()

  isSource: (loadedPath) ->
    relativePath = path.relative(@rootPath, loadedPath)
    for sourceName in @sourceNames
      return true if sourceName.match(relativePath)

  isIgnored: (loadedPath, stats) ->
    relativePath = path.relative(@rootPath, loadedPath)
    if @repo?.isPathIgnored(relativePath)
      true
    else
      for ignoredName in @ignoredNames
        return true if ignoredName.match(relativePath)

      return false

  isKnown: (loadedPath) -> loadedPath in @knownPaths

  hasChanged: (loadedPath, stats) ->
    if stats and @timestamp?
      stats.ctime >= @timestamp
    else
      false

  pathLoaded: (loadedPath, stats, done) ->
    @scannedPaths.push(loadedPath)
    if @isSource(loadedPath) and !@isIgnored(loadedPath, stats)
      if @isKnown(loadedPath)
        @paths.push(loadedPath) if @hasChanged(loadedPath, stats)
      else
        @paths.push(loadedPath)
    else
      @lostPaths.push(loadedPath) if loadedPath in @knownPaths

    @flushPaths() if @paths.length + @lostPaths.length is PathsChunkSize
    done()

  flushPaths: ->
    emit('load-paths:paths-found', @paths) if @paths.length
    emit('load-paths:paths-lost', @lostPaths) if @lostPaths.length
    @paths = []
    @lostPaths = []

  loadPath: (pathToLoad, done) ->
    return done() if @isIgnored(pathToLoad)
    fs.lstat pathToLoad, (error, stats) =>
      return done() if error?
      if stats.isSymbolicLink()
        fs.stat pathToLoad, (error, stats) =>
          return done() if error?
          if stats.isFile()
            @pathLoaded(pathToLoad, stats, done)
          else if stats.isDirectory()
            if @traverseSymlinkDirectories
              @loadFolder(pathToLoad, done)
            else
              done()
      else if stats.isDirectory()
        @loadFolder(pathToLoad, done)
      else if stats.isFile()
        @pathLoaded(pathToLoad, stats, done)
      else
        done()

  loadFolder: (folderPath, done) ->
    fs.readdir folderPath, (error, children=[]) =>
      async.each(
        children,
        (childName, next) =>
          @loadPath(path.join(folderPath, childName), next)
        done
      )

module.exports = (config) ->
  newConf =
    ignoreVcsIgnores: config.ignoreVcsIgnores
    traverseSymlinkDirectories: config.traverseSymlinkDirectories
    knownPaths: config.knownPaths
    ignoredNames: []
    sourceNames: []

  if config.timestamp?
    newConf.timestamp = new Date(Date.parse(config.timestamp))

  for source in config.sourceNames when source
    try
      newConf.sourceNames.push(new Minimatch(source, matchBase: true, dot: true))
    catch error
      console.warn "Error parsing source pattern (#{source}): #{error.message}"

  for ignore in config.ignoredNames when ignore
    try
      newConf.ignoredNames.push(new Minimatch(ignore, matchBase: true, dot: true))
    catch error
      console.warn "Error parsing ignore pattern (#{ignore}): #{error.message}"

  async.each(
    config.paths,
    (rootPath, next) ->
      new PathLoader(rootPath, newConf).load(next)
    @async()
  )
