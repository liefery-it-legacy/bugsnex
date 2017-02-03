defmodule Bugsnex.SystemTest do
  use ExUnit.Case

  test "hostname" do
    {:ok, current_hostname} = :inet.gethostname
    hostname = Bugsnex.System.hostname
    assert hostname == current_hostname
  end
end
