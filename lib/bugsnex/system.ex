defmodule Bugsnex.System do
  def hostname do
    {:ok, hostname} = :inet.gethostname()
    to_string(hostname)
  end
end
