Task = null

module.exports =
  startTask: (paths, registry, callback) ->
    Task ?= require('atom').Task

    results = []
    taskPath = require.resolve('./tasks/scan-paths-handler')

    @task = Task.once(
      taskPath,
      [paths, registry.serialize()],
      =>
        @task = null
        callback(results)
    )

    @task.on 'scan-paths:path-scanned', (result) ->
      results = results.concat(result)

    @task

  terminateRunningTask: ->
    @task?.terminate()
