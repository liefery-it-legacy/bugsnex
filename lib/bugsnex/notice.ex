defmodule Bugsnex.Notice do
  alias Bugsnex.Stacktrace

  @payload_version "2"
  @api_key Application.get_env(:bugsnex, :api_key)
  @release_stage Application.get_env(:bugsnex, :release_stage)
  @app %{
    releaseStage: @release_stage
  }

  defstruct apiKey: @api_key,
    notifier: %{
      name: "Bugsnex",
      version: Bugsnex.Mixfile.project[:version],
      url: "https://github.com/liefery/bugsnex"
    },
    events: [],
    context: nil,
    severity: "error",
    user: nil,
    device: nil,
    metaData: nil


  def new(exception, stacktrace) do
    %__MODULE__{}
      |> add_event(exception, stacktrace)
  end

  def add_event(notice, exception, stacktrace) do
      %{notice | events: [event_data(exception, stacktrace) | notice.events]}
  end

  def event_data(exception, stacktrace) do
    %{
      payloadVersion: @payload_version,
      app: @app,
      exceptions: [%{
                      errorClass: exception.__struct__,
                      message: Exception.message(exception),
                      stacktrace: Stacktrace.format(stacktrace)
               }]
    }
  end
end
