defmodule Bugsnex.NoticeTest do
  use ExUnit.Case
  alias Bugsnex.Notice

  @exception_message "The message of the exception!"
  @stacktrace [{TestModule, :some_function, 2, []}]
  @exception %ArgumentError{message: @exception_message}

  test "new notice contains the api key" do
    notice = Notice.new(@exception, @stacktrace)
    assert notice.apiKey == "TEST_API_KEY"
  end

  test "new notice contains the nofitifer data" do
    notice = Notice.new(@exception, @stacktrace)
    assert notice.notifier.name == "Bugsnex"
    assert notice.notifier.url == "https://github.com/liefery/bugsnex"
  end

  test "new notice has a default severity of `error`" do
    notice = Notice.new(@exception, @stacktrace)
    assert notice.severity == "error"
  end

  test "new notice contains the exception as event" do
    notice = Notice.new(@exception, @stacktrace)
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
    notice = Notice.new(@exception, @stacktrace)
    [event] =  notice.events
    assert event.app.releaseStage == "test_release_stage"
  end

end
