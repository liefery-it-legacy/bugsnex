defmodule Bugsnex.Stacktrace do

  def format(stacktrace) do
    Enum.map(stacktrace, &format_line/1)
  end

  defp format_line({mod, fun, arity, []}) do
    format_line({mod, fun, arity, [file: [], line: nil]})
  end

  defp format_line({mod, fun, arity, [file: file, line: line]}) do
    %{file: convert_string(file),
      method: Exception.format_mfa(mod, fun, arity),
      lineNumber: line,
      inProject: otp_app == get_app(mod)}
  end

  defp get_app(module) do
    case :application.get_application(module) do
      {:ok, app} -> app
      :undefined -> nil
    end
  end

  defp otp_app do
    Application.get_env(:bugsnex, :otp_app)
  end

  defp convert_string(""), do: nil
  defp convert_string(string) when is_binary(string), do: string
  defp convert_string(obj), do: to_string(obj) |> convert_string
end
