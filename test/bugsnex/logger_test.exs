defmodule Bugsnex.LoggerTest do
  use Bugsnex.BugsnexCase
  alias Bugsnex.{Logger, TestApi, TestErrorServer}
  import ExUnit.CaptureLog

  setup do
    :error_logger.add_report_handler(Logger)

    on_exit fn ->
      :error_logger.delete_report_handler(Logger)
    end
    {:ok, %{}}
  end


  @tag :capture_log
  test "logging a crash" do
    :proc_lib.spawn(fn ->
      raise RuntimeError, "Oops"
    end)
    assert_receive {:notice_sent, notice}
  end

  test "crashes do not cause recursive logging" do
    TestApi.start_crashing()
    captured_log = capture_log fn ->
      :proc_lib.spawn(fn ->
        raise RuntimeError, "raise_local_error"
      end)
      assert_receive {:notice_sent, _notice}
      refute_receive {:notice_sent, _notice}
    end
    assert captured_log =~ "[warn]  Unable to notify Bugsnex"
  end

  @tag :capture_log
  test "log levels lower than :error_report are ignored" do
    message_types = [:info_msg, :info_report, :warning_msg, :error_msg]

    Enum.each(message_types, fn(type) ->
      apply(:error_logger, type, ["Ignore me"])
      refute_receive {:notice_sent, _notice}
    end)
  end

  test "logging exceptions from special processes" do
    :proc_lib.spawn(fn ->
      Float.parse("12.345e308")
    end)

    assert_receive {:notice_sent, _notice}
  end

  @tag :capture_log
  test "logging exceptions from Tasks" do
    Task.start(fn ->
      Float.parse("12.345e308")
    end)

    assert_receive {notice_sent, _notice}
  end

  @tag :capture_log
  test "logging exceptions from GenServers" do
    {:ok, pid} = TestErrorServer.start
    GenServer.cast(pid, :fail)

    assert_receive {notice_sent, _notice}
  end
end
