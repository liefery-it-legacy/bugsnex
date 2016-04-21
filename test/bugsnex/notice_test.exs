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
    [event] =  notice.events
    assert event.payloadVersion == "2"
    [exception_data] = event.exceptions
    assert exception_data.errorClass == ArgumentError
    assert exception_data.message == @exception_message
    assert exception_data.stacktrace == [%{file: nil,
                                           inProject: false,
                                           lineNumber: nil,
                                           method: "TestModule.some_function/2"}]

  end

  test "new notice contains the app data" do
    notice = Notice.new(@exception, @stacktrace, @metadata)
    [event] =  notice.events
    assert event.app.releaseStage == "test_release_stage"
  end

  test "new notice contains user data if present in the metadata" do
    notice = Notice.new(@exception, @stacktrace, %{user: %{id: 123, name: "Max Mustermann"}})
    [event] =  notice.events
    assert event.user == %{id: 123, name: "Max Mustermann"}
  end

  test "new notice contains the context of the error if present in the metadata" do
    notice = Notice.new(@exception, @stacktrace, %{context: "UserSocket->CourierChannel->courier:123->handle_in"})
    [event] =  notice.events
    assert event.context == "UserSocket->CourierChannel->courier:123->handle_in"
  end

  test "new notice contains device data if present in the metadata" do
    notice = Notice.new(@exception, @stacktrace, %{device: %{osVersion: "2.1.1", hostname: "web1.internal"}})
    [event] =  notice.events
    assert event.device == %{osVersion: "2.1.1", hostname: "web1.internal"}
  end

  test "new notice contains all the meta data under the metaData key" do
    metadata = %{somekey: "somevalue", user: %{id: 123}}
    notice = Notice.new(@exception, @stacktrace, metadata)
    [event] =  notice.events
    assert event.metaData == metadata
  end
end
