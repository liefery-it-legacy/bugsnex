defmodule Bugsnex.Notice do
  alias Bugsnex.Stacktrace

  @payload_version "2"
  @api_key Application.get_env(:bugsnex, :api_key)
  @release_stage Application.get_env(:bugsnex, :release_stage)
  @app %{releaseStage: @release_stage}

  defstruct apiKey: @api_key,
    notifier: %{name: "Bugsnex",
      version: Bugsnex.Mixfile.project[:version],
      url: "https://github.com/liefery/bugsnex"},
    events: [],
    context: nil,
    severity: "error",
    user: nil,
    device: nil,
    metaData: nil


  def new(exception, stacktrace, metadata) do
    %__MODULE__{}
      |> add_event(%{exception: exception,
                     stacktrace: stacktrace,
                     metadata: metadata})
  end

  def add_event(notice, data) do
      %{notice | events: [event_data(data) | notice.events]}
  end

  def event_data(%{exception: exception, stacktrace: stacktrace, metadata: metadata}) do
    %{payloadVersion: @payload_version,
      app: @app,
      exceptions: [exception_data(exception, stacktrace)]}
    |> add_metadata(metadata)
  end

  def exception_data(exception, stacktrace) do
    exception = Exception.normalize(:error, exception)
    %{
      errorClass: exception.__struct__,
      message: Exception.message(exception),
      stacktrace: Stacktrace.format(stacktrace)
    }
  end

  def add_metadata(event_data, metadata) do
    event_data
    |> put_user_data(metadata)
    |> put_context_data(metadata)
    |> put_device_data(metadata)
    |> Map.put(:metaData, metadata)
  end

  def put_user_data(event_data, %{user: user_data}) do
    Map.put(event_data, :user, user_data)
  end
  def put_user_data(event_data, _), do: event_data

  def put_context_data(event_data, %{context: context}) do
    Map.put(event_data, :context, context)
  end
  def put_context_data(event_data, _), do: event_data

  def put_device_data(event_data, %{device: device}) do
    Map.put(event_data, :device, device)
  end
  def put_device_data(event_data, _), do: event_data
end
