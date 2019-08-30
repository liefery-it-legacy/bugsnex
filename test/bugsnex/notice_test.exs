defmodule Bugsnex.NoticeTest do
  use ExUnit.Case
  alias Bugsnex.Notice

  @exception_message "The message of the exception!"
  @stacktrace [{TestModule, :some_function, 2, []}]
  @exception %ArgumentError{message: @exception_message}
  @metadata %{}

  test "new notice contains the api key" do
    notice = Notice.new(@exception, @stacktrace, @metadata)
    assert notice.apiKey == "TEST_API_KEY"
  end

  test "new notice contains the nofitifer data" do
    notice = Notice.new(@exception, @stacktrace, @metadata)
    assert notice.notifier.name == "Bugsnex"
    assert notice.notifier.url == "https://github.com/liefery/bugsnex"
  end

  test "new notice has a default severity of `error`" do
    notice = Notice.new(@exception, @stacktrace, @metadata)
    assert notice.severity == "error"
  end

  test "new notice contains the exception as event" do
    notice = Notice.new(@exception, @stacktrace, @metadata)
    assert [event] = notice.events
    assert event.payloadVersion == "2"
    assert [exception_data] = event.exceptions
    assert exception_data.errorClass == ArgumentError
    assert exception_data.message == @exception_message

    assert exception_data.stacktrace == [
             %{file: nil, inProject: false, lineNumber: nil, method: "TestModule.some_function/2"}
           ]
  end

  test "new notice contains the app data" do
    notice = Notice.new(@exception, @stacktrace, @metadata)
    assert [event] = notice.events
    assert event.app.releaseStage == "test_release_stage"
  end

  test "new notice contains user data if present in the metadata" do
    notice = Notice.new(@exception, @stacktrace, %{user: %{id: 123, name: "Max Mustermann"}})
    assert [event] = notice.events
    assert event.user == %{id: 123, name: "Max Mustermann"}
  end

  test "new notice contains the context of the error if present in the metadata" do
    notice =
      Notice.new(@exception, @stacktrace, %{
        context: "UserSocket->CourierChannel->courier:123->handle_in"
      })

    assert [event] = notice.events
    assert event.context == "UserSocket->CourierChannel->courier:123->handle_in"
  end

  test "new notice contains device data if present in the metadata" do
    notice = Notice.new(@exception, @stacktrace, %{device: %{osVersion: "2.1.1"}})
    assert [event] = notice.events
    assert event.device == %{osVersion: "2.1.1", host: "myhost.local"}
  end

  test "new notice contains hostname in device data" do
    notice = Notice.new(@exception, @stacktrace, %{})
    assert [event] = notice.events
    assert event.device == %{host: "myhost.local"}
  end

  test "new notice contains all the meta data under the metaData key" do
    metadata = %{somekey: "somevalue", user: %{id: 123}}
    notice = Notice.new(@exception, @stacktrace, metadata)
    assert [event] = notice.events
    assert event.metaData == metadata
  end

  test ".device_defaults contains the systems hostname" do
    defaults = Notice.device_defaults(Bugsnex.System)
    {:ok, hostname} = :inet.gethostname()
    assert defaults == %{host: to_string(hostname)}
  end

  test "new notice supports runtime configuration" do
    old_api_key = Application.get_env(:bugsnex, :api_key)
    old_release_stage = Application.get_env(:bugsnex, :release_stage)

    Application.put_env(:bugsnex, :api_key, "TEST_API_KEY_OVERRIDE")
    Application.put_env(:bugsnex, :release_stage, "TEST_RELEASE_STAGE_OVERRIDE")

    notice = Notice.new(@exception, @stacktrace, @metadata)
    [event] = notice.events

    assert notice.apiKey == "TEST_API_KEY_OVERRIDE"
    assert event.app.releaseStage == "TEST_RELEASE_STAGE_OVERRIDE"

    Application.put_env(:bugsnex, :api_key, old_api_key)
    Application.put_env(:bugsnex, :release_stage, old_release_stage)
  end
end
