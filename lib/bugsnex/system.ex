defmodule Bugsnex.System do
  def hostname do
    {:ok, hostname} = :inet.gethostname
    hostname
  end
end
