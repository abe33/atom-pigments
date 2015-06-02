{Task} = require 'atom'

module.exports =
  startTask: (config, callback) ->
    projectPaths = []
    taskPath = require.resolve('./tasks/load-paths-handler')

    task = Task.once(
      taskPath,
      config,
      -> callback(projectPaths)
    )

    task.on 'load-paths:paths-found', (paths) ->
      projectPaths.push(paths...)

    task
