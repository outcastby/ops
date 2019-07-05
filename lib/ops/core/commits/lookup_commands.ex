defmodule Ops.Commits.LookupCommands do
  def call(text) do
    text
    |> String.split("/")
    |> Enum.map(&String.split(&1, "~"))
    |> Enum.filter(&Enum.member?(Ops.Utils.Config.lookup_available_commands(), List.first(&1)))
    |> enhance_by_default_commands()
  end

  defp enhance_by_default_commands(commands) do
    commands
    |> enhance_by_build()
    |> Enum.uniq_by(&List.first(&1))
  end

  defp enhance_by_build(commands) do
    case enhance_by_build?(commands) do
      true -> [["build"]] ++ commands
      _ -> commands
    end
  end

  defp enhance_by_build?(commands) do
    Enum.any?(commands, &(List.first(&1) in Ops.Utils.Config.lookup_built_depends())) ||
      Enum.any?(Ops.Utils.Config.lookup_built_branches(), &(Ops.Utils.Git.lookup_branch() =~ &1))
  end
end
