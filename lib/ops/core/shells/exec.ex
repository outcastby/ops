defmodule Ops.Shells.Exec do
  def call(exe, args, opts \\ [:stream]) when is_list(args) do
    opts = opts ++ [{:args, args}, :binary, :exit_status, :hide, :use_stdio, :stderr_to_stdout]
    {:spawn_executable, exe} |> Port.open(opts) |> handle_output()
  end

  def handle_output(port) do
    receive do
      {^port, {:data, {_, result}}} ->
        IO.inspect(result)
        handle_output(port)

      {^port, {:exit_status, status}} ->
        case status do
          0 -> status
          _ -> exit("Shell script stopped with error, status - #{status}")
        end
    end
  end
end
