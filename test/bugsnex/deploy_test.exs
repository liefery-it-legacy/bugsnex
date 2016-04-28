defmodule Bugsnex.DeployTest do
  use ExUnit.Case
  alias Bugsnex.Deploy

  test "new returns a deploy struct with default parameters" do
    deploy = Deploy.new
    assert deploy.apiKey == "TEST_API_KEY"
    assert deploy.releaseStage == "test_release_stage"
    assert deploy.repository == "the://repository.url"
  end

  test "new merges default with provided parameters" do
    deploy = Deploy.new(%{releaseStage: "another_release_stage", appVersion: "0.1.2"})
    assert deploy.apiKey == "TEST_API_KEY"
    assert deploy.releaseStage == "another_release_stage"
    assert deploy.appVersion == "0.1.2"
  end

end
