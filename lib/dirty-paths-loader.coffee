{Task} = require 'atom'

module.exports =
  startTask: (config, callback) ->
    projectPaths = []
    taskPath = require.resolve('./tasks/load-dirty-paths-handler')
    config.traverseIntoSymlinkDirectories = atom.config.get 'pigments.traverseIntoSymlinkDirectories'
    config.sourceNames = atom.config.get('pigments.sourceNames') ? []

    config.ignoredNames = config.ignores ? []
    config.ignoredNames = config.ignoredNames.concat(atom.config.get('pigments.ignoredNames') ? [])
    config.ignoredNames = config.ignoredNames.concat(atom.config.get('core.ignoredNames') ? [])
    config.ignoreVcsIgnores = atom.config.get('core.excludeVcsIgnoredPaths')

    task = Task.once(
      taskPath,
      config,
      -> callback(projectPaths)
    )

    task.on 'load-paths:paths-found', (paths) ->
      projectPaths.push(paths...)

    task
