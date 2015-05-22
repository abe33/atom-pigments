{Task} = require 'atom'

module.exports =
  startTask: (paths, callback) ->
    results = []
    taskPath = require.resolve('./tasks/scan-paths-handler')

    @task = Task.once(
      taskPath,
      paths,
      =>
        @task = null
        callback(results)
    )

    @task.on 'scan-paths:path-scanned', (result) ->
      results = results.concat(result)

    @task

  terminateRunningTask: ->
    @task?.terminate()
