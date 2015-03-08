{Task} = require 'atom'

module.exports =
  startTask: (project, callback) ->
    projectPaths = []
    taskPath = require.resolve('./load-paths-handler')
    traverseIntoSymlinkDirectories = atom.config.get 'pigments.traverseIntoSymlinkDirectories'
    sourceNames = atom.config.get('pigments.sourceNames') ? []

    ignoredNames = project.ignores ? []
    ignoredNames = ignoredNames.concat(atom.config.get('pigments.ignoredNames') ? [])
    ignoredNames = ignoredNames.concat(atom.config.get('core.ignoredNames') ? [])
    ignoreVcsIgnores = atom.config.get('core.excludeVcsIgnoredPaths')

    task = Task.once(
      taskPath,
      atom.project.getPaths(),
      sourceNames,
      traverseIntoSymlinkDirectories,
      ignoreVcsIgnores,
      ignoredNames,
      -> callback(projectPaths)
    )

    task.on 'load-paths:paths-found', (paths) ->
      projectPaths.push(paths...)

    task
