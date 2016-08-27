Task = null

module.exports =
  startTask: (config, callback) ->
    Task ?= require('atom').Task

    dirtied = []
    removed = []
    taskPath = require.resolve('./tasks/load-paths-handler')

    task = Task.once(
      taskPath,
      config,
      -> callback({dirtied, removed})
    )

    task.on 'load-paths:paths-found', (paths) -> dirtied.push(paths...)
    task.on 'load-paths:paths-lost', (paths) -> removed.push(paths...)

    task
