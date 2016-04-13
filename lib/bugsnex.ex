defmodule Bugsnex do
  use Application
  import Bugsnex.Util
  alias Bugsnex.{Notice, NotificationTaskSupervisor}

  @api_module Application.get_env(:bugsnex, :api_module, Bugsnex.Api)

  def start(_type, _args) do
    {:ok, task_supervisor_pid} = Task.Supervisor.start_link([name: NotificationTaskSupervisor])

    if Application.get_env(:bugsnex, :use_logger) do
      :error_logger.add_report_handler(Bugsnex.Logger)
    end

    {:ok, task_supervisor_pid}
  end

  def notify(exception) do
    {:current_stacktrace, stacktrace} = Process.info(self, :current_stacktrace)
    notify(exception, stacktrace)
  end

  def notify(exception, stacktrace) do
    metadata = get_metadata()
    notify(exception, stacktrace, metadata)
  end

  def notify(exception, stacktrace, metadata) do
    Task.Supervisor.start_child(NotificationTaskSupervisor, fn -> do_notify(exception, stacktrace, metadata) end)
  end

  def do_notify(exception, stacktrace, metadata) do
    try do
      notice = Notice.new(exception, stacktrace, metadata)
      @api_module.send_notice(notice)
    rescue
      exception -> log_exception_after_error(exception)
    end
  end


  @metadata_key "bugsnex_metadata"
  def get_metadata do
    (Process.get(@metadata_key) || %{}) |> Enum.into(Map.new)
  end

  def put_metadata(dict) do
    Process.put(@metadata_key, Dict.merge(get_metadata, dict))
  end

end
