defmodule Bugsnex.SystemTest do
  use ExUnit.Case

  test "hostname" do
    {:ok, current_hostname} = :inet.gethostname
    hostname = Bugsnex.System.hostname
    assert is_binary(hostname)
    assert hostname == to_string(current_hostname)
  end
end
