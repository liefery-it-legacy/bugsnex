defmodule Bugsnex.Logger do
  import Bugsnex.Util
  use GenEvent


  def init(_mod, []), do: {:ok, []}

  def handle_call({:configure, new_keys}, _state) do
    {:ok, :ok, new_keys}
  end

  def handle_event({_level, group_leader, _event}, state) when node(group_leader) != node() do
    {:ok, state}
  end

  def handle_event({:error_report, _gl, {_pid, _type, [message | _]}}, state)
  when is_list(message) do
    try do
      error_info = message[:error_info]

      case error_info do
        {_kind, {exception, stacktrace}, _stack} when is_list(stacktrace) ->
          Bugsnex.notify(exception, stacktrace)
        {_kind, exception, stacktrace} ->
          Bugsnex.notify(exception, stacktrace)
      end
    rescue
      exception -> log_exception_after_error(exception)
    end

    {:ok, state}
  end

  def handle_event({_level, _gl, _event}, state) do
    {:ok, state}
  end
end
