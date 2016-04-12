defmodule Bugsnex do
  use Application
  alias Bugsnex.{Notice, NotificationTaskSupervisor}

  @api_module Application.get_env(:bugsnex, :api_module, Bugsnex.Api)

  def start(_type, _args) do
    Task.Supervisor.start_link([name: NotificationTaskSupervisor])
  end

  def notify(exception) do
    {:current_stacktrace, stacktrace} = Process.info(self, :current_stacktrace)
    notify(exception, stacktrace)
  end

  def notify(exception, stacktrace) do
    Task.Supervisor.start_child(NotificationTaskSupervisor, fn -> do_notify(exception, stacktrace) end)
  end

  def do_notify(exception, stacktrace) do
    notice = Notice.new(exception, stacktrace)
    @api_module.send_notice(notice)
  end

end
