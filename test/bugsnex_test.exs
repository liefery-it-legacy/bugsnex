defmodule BugsnexTest do
  use ExUnit.Case
  alias Bugsnex.TestApi

  setup do
    {:ok, _pid} = TestApi.start_link
    TestApi.subscribe(self)
    {:ok, %{}}
  end

  test "notify sends a notice to the api" do
    stacktrace = [{Stacktrace,  :format, 1, []}]
    exception = %ArgumentError{message: "bad!!"}
    Bugsnex.notify(exception, stacktrace)

    assert_receive {:notice_sent, notice}

    [%{exceptions: [passed_exception]}] = notice.events
    assert passed_exception.errorClass == ArgumentError
    assert [%{method: "Stacktrace.format/1"}] = passed_exception.stacktrace
  end

  test "notify adds the current stacktrace if none is provided" do
    exception = %ArgumentError{message: "bad!!"}
    Bugsnex.notify(exception)

    assert_receive {:notice_sent, notice}

    [%{exceptions: [passed_exception]}] = notice.events
    assert Enum.any?(passed_exception.stacktrace, fn line ->
      line.file == "test/bugsnex_test.exs"
    end)
  end
end
