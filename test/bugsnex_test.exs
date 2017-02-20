defmodule BugsnexTest do
  use Bugsnex.BugsnexCase

  setup do
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

  @tag :capture_log
  test "notify does not raise an error if notification fails" do
    exception = %ArgumentError{message: "raise_local_error"}
    Bugsnex.notify(exception)
  end

  test "notify puts the calling processes metadata into the notice" do
    Bugsnex.put_metadata(%{user: %{id: 678}})
    exception = %ArgumentError{message: "bad!!"}
    Bugsnex.notify(exception)
    assert_receive {:notice_sent, notice}
    [event] = notice.events
    assert event.user == %{id: 678}
  end

  test "setting and getting the metadata" do
    Bugsnex.put_metadata(%{user: 123})
    spawn_link fn ->
      Bugsnex.put_metadata(%{user: 678})
      assert Bugsnex.get_metadata.user == 678
    end
    assert Bugsnex.get_metadata.user == 123
  end

  test ".put_metadata works with keyword list (regression)" do
    Bugsnex.put_metadata(foo: "bar")
    spawn_link fn ->
      Bugsnex.put_metadata(user: 678)
      assert Bugsnex.get_metadata.user == 678
    end
    assert Bugsnex.get_metadata.foo == "bar"
  end

  test "track_deploy sends a deploy notification to the api" do
    Bugsnex.track_deploy()

    assert_receive {:deploy_sent, deploy}
    assert deploy.apiKey
  end

  test "track_deploy forwards deploy parameter" do
    Bugsnex.track_deploy(%{:revision => "some_sha"})

    assert_receive {:deploy_sent, deploy}
    assert deploy.revision == "some_sha"
  end

  test "handle_errors returns the result of the block if no error was raised" do
    require Bugsnex
    result = Bugsnex.handle_errors do
      :some_value
    end
    assert result == :some_value
  end

  test "handle_errors sends exception and metadata to bugsnag" do
    require Bugsnex
    catch_error(fn ->
      Bugsnex.handle_errors %{some: "metadata"} do
        raise "an error"
      end
    end.())

    assert_receive({:notice_sent, notice})
    [event] = notice.events
    assert event.metaData.some == "metadata"
  end
end
