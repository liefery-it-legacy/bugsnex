defmodule Bugsnex.PlugTest do
  use Bugsnex.BugsnexCase
  use Plug.Test

  defmodule PhoenixApp do
    use Phoenix.Router
  end

  defmodule PlugApp do
    import Plug.Conn
    use Plug.Router
    use Bugsnex.Plug

    plug :match
    plug :dispatch

    get "/bang" do
      _ = conn
      raise RuntimeError, "Oops"
    end

    get "/non_important_bang" do
      _ = conn
      raise %Plug.BadRequestError{}
    end
  end


  test "exceptions on a non-existant route are ignored" do
    conn = conn(:get, "/not_found")

    assert :function_clause = catch_error(PlugApp.call conn, [])
    refute_receive({:notice_sent, _notice})
  end

  test "exceptions on a non-existant phoenix route are ignored" do
    conn = conn(:get, "/not_found")

    assert %Phoenix.Router.NoRouteError{} = catch_error(PhoenixApp.call conn, [])
    refute_receive({:notice_sent, _notice})
  end

  test "doesn't fail if the session cannot be fetched" do
    conn = conn(:get, "/bang")
    catch_error(PlugApp.call conn, [])

    assert_receive({:notice_sent, _notice})
  end

  test "exceptions that have a plug status of < 500 are ignored" do
    conn = conn(:get, "/non_important_bang")
    catch_error(PlugApp.call(conn, []))

    refute_receive({:notice_sent, _notice})
  end

  test "sends metadata to bugsnag" do
    Bugsnex.put_metadata(%{user: %{id: 1234}})
    conn = conn(:get, "/bang", %{:test_param => 42})
    |> with_session
    |> Plug.Conn.put_session(:testkey, :testvalue)

    catch_error(PlugApp.call conn, [])

    assert_receive({:notice_sent, notice})
    [event] = notice.events
    assert event.context == "/bang"
    assert event.metaData.request == Bugsnex.Plug.build_request_data(conn)
    assert event.metaData.session == %{"testkey" => :testvalue}
    assert event.metaData.params == %{"test_param" => 42}
    assert event.user == %{id: 1234}
  end

  test "build_plug_env/2" do
    conn = conn(:get, "/bang?foo=bar&password=password&password_confirmation=password")
    plug_env = %{request: Bugsnex.Plug.build_request_data(conn),
                 context: "/bang",
                 params: %{"foo" => "bar", "password" => "[FILTERED]", "password_confirmation" => "[FILTERED]"},
                 session: %{}}

    assert plug_env == Bugsnex.Plug.build_plug_env(conn)
  end

  test "build_plug_env/2 also filters a deep map" do
    params =  %{
      "foo" => "bar",
      "map" => %{
        "b" => %{"api_key" => "secret"}
      }
    }
    query_string = Plug.Conn.Query.encode(params)
    conn = conn(:get, "/bang?#{query_string}")
    plug_env = %{request: Bugsnex.Plug.build_request_data(conn),
                 context: "/bang",
                 params: %{"foo" => "bar", "map" => %{"b" => %{"api_key" => "[FILTERED]"}}},
                 session: %{}}

    assert plug_env == Bugsnex.Plug.build_plug_env(conn)
  end

  test "build_plug_env/2 also filters a file upload" do
    params =  %{
      foo: "bar",
      file: %Plug.Upload{content_type: "text/csv", filename: "test.csv", path: "/path/to/tempfile"}
    }
    conn = conn(:get, "/bang", params)
    plug_env = %{request: Bugsnex.Plug.build_request_data(conn),
                 context: "/bang",
                 params: %{"foo" => "bar", "file" => %{:content_type => "text/csv", :filename => "test.csv", :path => "/path/to/tempfile"}},
                 session: %{}}

    assert plug_env == Bugsnex.Plug.build_plug_env(conn)
  end

  test "build_plug_env/2 also filters a list" do
    params =  %{"foo" => [%{"password_confirmation" => "secret"}]}

    query_string = Plug.Conn.Query.encode(params)
    conn = conn(:get, "/bang?#{query_string}")
    plug_env = %{request: Bugsnex.Plug.build_request_data(conn),
                 context: "/bang",
                 params: %{"foo" => [%{"password_confirmation" => "[FILTERED]"}]},
                 session: %{}}

    assert plug_env == Bugsnex.Plug.build_plug_env(conn)
  end


  test "build_plug_env/2 also filters a deep map with a list" do
    params =  %{
      "foo" => "bar",
      "map" => %{
        "a" => "1",
        "b" => [%{"password" => "secret"}]
      }
    }
    query_string = Plug.Conn.Query.encode(params)
    conn = conn(:get, "/bang?#{query_string}")
    plug_env = %{request: Bugsnex.Plug.build_request_data(conn),
                 context: "/bang",
                 params: %{"foo" => "bar", "map" => %{"a" => "1", "b" => [%{"password" => "[FILTERED]"}]}},
                 session: %{}}

    assert plug_env == Bugsnex.Plug.build_plug_env(conn)
  end

  test "build_request_data/1" do
    Application.put_env(:bugsnex, :hostname, "hostname.local")
    conn = conn(:get, "/bang")
      |> put_req_header("content-type", "application/json")
    remote_port = Plug.Conn.get_peer_data(conn).port
    cgi_data = %{"CONTENT_LENGTH" => [],
                 "ORIGINAL_FULLPATH" => "/bang",
                 "PATH_INFO" => "bang",
                 "QUERY_STRING" => "",
                 "REMOTE_ADDR" => "127.0.0.1",
                 "REMOTE_PORT" => remote_port,
                 "REQUEST_METHOD" => "GET",
                 "SCRIPT_NAME" => "",
                 "SERVER_ADDR" => "127.0.0.1",
                 "SERVER_NAME" => "hostname.local",
                 "SERVER_PORT" => 80,
                 "content-type" => "application/json"}

    assert cgi_data == Bugsnex.Plug.build_request_data(conn)
  end

  test "get_remote_addr/1" do
    assert "127.0.0.1" == Bugsnex.Plug.get_remote_addr({127, 0, 0, 1})
  end

  test "get_hostname/0" do
    Application.put_env(:bugsnex, :hostname, "the_hostname")
    assert Bugsnex.Plug.get_hostname == "the_hostname"

    Application.delete_env(:bugsnex, :hostname)
    assert is_binary(Bugsnex.Plug.get_hostname) #depends on the system, so we just make sure it's a string
  end

  defp with_session(conn) do
    session_opts = Plug.Session.init(store: :cookie, key: "_app",
                                     encryption_salt: "abc", signing_salt: "abc")
    conn
    |> Map.put(:secret_key_base, String.duplicate("abcdefgh", 8))
    |> Plug.Session.call(session_opts)
    |> Plug.Conn.fetch_session()
  end
end
