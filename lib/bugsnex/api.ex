defmodule Bugsnex.Api do
  use HTTPoison.Base


  def process_url(path) do
    base_url <> path
  end

  defp process_request_headers(headers) do
    [{"Content-Type", "application/json"} | headers]
  end

  def send_notice(notice) do
    body = Poison.encode!(notice)
    post("/", body)
  end

  defp base_url do
    Application.get_env(:bugsnex, :base_url, "https://notify.bugsnag.com")
  end

end
