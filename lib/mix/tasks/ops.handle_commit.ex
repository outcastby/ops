defmodule Mix.Tasks.Ops.HandleCommit do
  use Mix.Task

  @shortdoc "Handle commit message"

  @moduledoc """
  Parse last commit message. If on last row we detect commands, we execute them ('-f' - this flag mean fast)

  Examples:

  build
  uat/staging
  uat~-f
  """

  @doc false
  def run(_args) do
    commands = Ops.Utils.Git.lookup_commit_message_last_row() |> Ops.Commits.LookupCommands.call()
    Ops.Utils.Io.puts("Follow commands will be processed by comment message: #{inspect(commands)}")

    commands |> Enum.each(&run_command(List.first(&1), &1))
  end

  def run_command("build", _), do: Mix.Tasks.Ops.Build.run([])
  def run_command("prod", _), do: nil
  def run_command(_, flags), do: Mix.Tasks.Ops.Deploy.run(flags)
end
