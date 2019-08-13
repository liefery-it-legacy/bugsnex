defmodule Bugsnex.StacktraceTest do
  use ExUnit.Case
  alias Bugsnex.Stacktrace

  test "format without file info" do
    line = {TestModule, :some_function, 2, []}
    [formatted_line] = Stacktrace.format([line])
    assert formatted_line.file == nil
    assert formatted_line.lineNumber == nil
  end

  test "format with file info" do
    line = {TestModule, :some_function, 2, [file: 'lib/process.ex', line: 443]}
    [formatted_line] = Stacktrace.format([line])
    assert formatted_line.file == "lib/process.ex"
    assert formatted_line.lineNumber == 443
  end

  test "format includes the MFA as method name" do
    line = {TestModule, :some_function, 2, []}
    [formatted_line] = Stacktrace.format([line])
    assert formatted_line.method == "TestModule.some_function/2"
  end

  test "inProject is true if the module is in the same otp application" do
    line = {:timer, :sleep, 1, []}
    [formatted_line] = Stacktrace.format([line])
    assert formatted_line.inProject == true
  end

  test "inProject is false if the module is not in the same otp application" do
    line = {Stacktrace, :format, 1, []}
    [formatted_line] = Stacktrace.format([line])
    assert formatted_line.inProject == false
  end
end
