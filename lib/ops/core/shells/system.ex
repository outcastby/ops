defmodule Ops.Shells.System do
  def call(command, args \\ []) do
    case System.cmd(command, args) do
      {result, 0} -> result |> String.trim("\n") |> String.trim()
      _ -> nil
    end
  end
end
