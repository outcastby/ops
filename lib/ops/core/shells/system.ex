defmodule Ops.Shells.System do
  def call(command, args \\ [], parse_json \\ false) do
    case System.cmd(command, args) do
      {result, 0} -> result |> String.trim("\n") |> String.trim() |> handle_result(parse_json)
      _ -> nil
    end
  end

  def handle_result(result, false), do: result

  def handle_result(result, true) do
    Jason.decode!(result)
  rescue
    _ -> nil
  end
end
