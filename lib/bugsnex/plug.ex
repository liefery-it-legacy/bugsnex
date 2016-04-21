defmodule Bugsnex.Plug do
  defmacro __using__(_env) do
    quote do
      import Bugsnex.Plug
      use Plug.ErrorHandler
      require Bugsnex

      # Exceptions raised on non-existant Plug routes are ignored
      defp handle_errors(conn, %{reason: %FunctionClauseError{function: :do_match}} = ex) do
        nil
      end

      if :code.is_loaded(Phoenix) do
        # Exceptions raised on non-existant Phoenix routes are ignored
        defp handle_errors(conn, %{reason: %Phoenix.Router.NoRouteError{}} = ex) do
          nil
        end
      end

      defp handle_errors(conn, %{kind: _kind, reason: exception, stack: stack}) do
        metadata = conn
          |> build_plug_env
          |> Map.merge(Bugsnex.get_metadata())

        Bugsnex.notify(exception, stack, metadata)
      end
    end
  end

  def build_plug_env(%Plug.Conn{} = conn) do
    {conn, session} = try do
      conn = Plug.Conn.fetch_session(conn)
      {conn, conn.private.plug_session}
    rescue
      _ in [ArgumentError, KeyError] ->
        # just return conn and move on
        {conn, %{}}
    end

    conn = Plug.Conn.fetch_query_params(conn)

    %{context: conn.request_path,
      params: conn.params,
      session: session,
      request: build_request_data(conn)}
  end

  def build_request_data(%Plug.Conn{} = conn) do
    rack_env_http_vars = Enum.into conn.req_headers, %{}
    request_data = %{
      "REQUEST_METHOD" => conn.method,
      "PATH_INFO" => Enum.join(conn.path_info, "/"),
      "QUERY_STRING" => conn.query_string,
      "SCRIPT_NAME" => Enum.join(conn.script_name, "/"),
      "REMOTE_ADDR" => get_remote_addr(conn.remote_ip),
      "REMOTE_PORT" => get_remote_port(conn.peer),
      "SERVER_ADDR" => "127.0.0.1",
      "SERVER_NAME" => get_hostname(),
      "SERVER_PORT" => conn.port,
      "CONTENT_LENGTH" => Plug.Conn.get_req_header(conn, "content-length"),
      "ORIGINAL_FULLPATH" => conn.request_path
    }

    Map.merge(rack_env_http_vars, request_data)
  end

  def get_remote_addr(addr), do: :inet.ntoa(addr) |> List.to_string
  def get_remote_port({_, port}), do: port

  def get_hostname do
    Application.get_env(:bugsnex, :hostname) || get_system_hostname()
  end

  defp get_system_hostname do
    {:ok, hostname} = :inet.gethostname
    to_string(hostname)
  end
end
