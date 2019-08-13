defmodule Bugsnex.ApiTest do
  use ExUnit.Case
  alias Bugsnex.Api
  alias Plug.Conn

  setup do
    bypass = Bypass.open()
    Application.put_env(:bugsnex, :base_url, "http://localhost:#{bypass.port}")
    {:ok, %{bypass: bypass}}
  end

  test "send_notice adds the json content type header", %{bypass: bypass} do
    Bypass.expect(bypass, fn conn ->
      assert {"content-type", "application/json"} in conn.req_headers
      Conn.resp(conn, 200, "ok")
    end)

    Api.send_notice(%{the: :notice})
  end

  test "send_notice sends the json encoded notice as body", %{bypass: bypass} do
    notice = %{"the" => "notice"}

    Bypass.expect(bypass, fn conn ->
      {:ok, body, conn} = Conn.read_body(conn)
      assert Poison.decode!(body) == notice
      Conn.resp(conn, 200, "ok")
    end)

    Api.send_notice(notice)
  end

  test "send_deploy sends a deploy notification to bugsnag", %{bypass: bypass} do
    deploy = %{"apiKey" => "some key"}

    Bypass.expect(bypass, fn conn ->
      {:ok, body, conn} = Conn.read_body(conn)
      assert conn.request_path == "/deploy"
      assert Poison.decode!(body) == deploy
      Conn.resp(conn, 200, "ok")
    end)

    Api.send_deploy(deploy)
  end
end
