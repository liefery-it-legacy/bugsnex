defmodule Bugsnex.Deploy do

  @api_key Application.get_env(:bugsnex, :api_key)
  @release_stage Application.get_env(:bugsnex, :release_stage)
  @repository_url Application.get_env(:bugsnex, :repository_url)

  defstruct apiKey: @api_key,
    repository: @repository_url,
    releaseStage: @release_stage,
    branch: nil,
    revision: nil,
    appVersion: nil

  def new(params \\ %{}) do
    Map.merge(%__MODULE__{}, params)
  end
end
