defmodule Bugsnex.Util do
  require Logger

  @doc """
  Use this to write "errors during bugsnex error handling" to the local log.
  We only send `error` log entries to bugsnag, so `warn` level should not
  trigger our error handling again.
  """
  def log_exception_after_error(exception) do
    try do
      error_type = exception.__struct__
      reason = Exception.message(exception)
      {:current_stacktrace, stacktrace} = Process.info(self(), :current_stacktrace)
      message = "Unable to notify Bugsnex! #{error_type}: #{reason}\n#{inspect(stacktrace)}"
      Logger.warn(message)
    rescue
      _ -> :ok
    end
  end
end
