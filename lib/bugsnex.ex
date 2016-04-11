defmodule Bugsnex do
  alias Bugsnex.{Notice, Api}

  def notify(exception) do
    {:current_stacktrace, stacktrace} = Process.info(self, :current_stacktrace)
    notify(exception, stacktrace)
  end

  def notify(exception, stacktrace) do
    notice = Notice.new(exception, stacktrace)
    Api.send_notice(notice)
  end

end
