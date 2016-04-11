defmodule Bugsnex do
  alias Bugsnex.Notice

  @api_module Application.get_env(:bugsnex, :api_module, Bugsnex.Api)

  def notify(exception) do
    {:current_stacktrace, stacktrace} = Process.info(self, :current_stacktrace)
    notify(exception, stacktrace)
  end

  def notify(exception, stacktrace) do
    notice = Notice.new(exception, stacktrace)
    @api_module.send_notice(notice)
  end

end
