defmodule Ops.Shells.Exec do
  def call(exe, args, opts \\ [:stream], exit_on_error \\ true) when is_list(args) do
    opts = opts ++ [{:args, args}, :binary, :exit_status, :hide, :use_stdio, :stderr_to_stdout]
    {:spawn_executable, exe} |> Port.open(opts) |> handle_output(exit_on_error)
  end

  def handle_output(port, exit_on_error) do
    receive do
      {^port, {:data, data}} ->
        {_, result} = data
        IO.inspect(result)
        handle_output(port, exit_on_error)

      {^port, {:exit_status, status}} ->
        if exit_on_error && status != 0, do: process_exit(status)
        status
    end
  end

  def process_exit(status), do: exit("Shell script stopped with error, status - #{status}")
end
