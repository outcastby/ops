defmodule Ops.Utils.Aws do
  require IEx
  require Logger

  @nodes_type "t3.medium"
  @nodes_size "2"
  @nodes_min_size "2"
  @nodes_max_size "2"

  def region(), do: Ops.Utils.Config.settings()[:aws_configuration][:region]
  def nodes_type(), do: Ops.Utils.Config.settings()[:aws_configuration][:nodes_type] || @nodes_type
  def nodes_size(), do: Ops.Utils.Config.settings()[:aws_configuration][:nodes_size] || @nodes_size
  def nodes_min_size(), do: Ops.Utils.Config.settings()[:aws_configuration][:nodes_min_size] || @nodes_min_size
  def nodes_max_size(), do: Ops.Utils.Config.settings()[:aws_configuration][:nodes_max_size] || @nodes_max_size

  def cmd(args) do
    case "aws" |> System.find_executable() |> Ops.Shells.System.call(args) do
      nil -> nil
      "" -> ""
      response -> Jason.decode!(response)
    end
  end

  def get_user_name(), do: cmd(["iam", "get-user"]) |> get_in(["User", "UserName"])
  def get_user_groups(), do: cmd(["iam", "list-groups-for-user", "--user-name", get_user_name()]) |> get_in(["Groups"])
  def get_user_group_by_name(name), do: get_user_groups() |> Enum.find(&(&1["GroupName"] == name))
  def get_stacks(), do: cmd(["cloudformation", "list-stacks"]) |> get_in(["StackSummaries"])
  def get_stack_by_name(name), do: get_stacks() |> Enum.find(&(&1["StackName"] == name))
  def get_cluster_by_name(name), do: cmd(["eks", "describe-cluster", "--name", name]) |> get_in(["cluster"])

  def delete_stack(name), do: cmd(["cloudformation", "delete-stack", "--stack-name", name])

  def create_cluster_and_nodes(name) do
    args = [
      "create",
      "cluster",
      "--name",
      name,
      "--version",
      "1.13",
      "--nodegroup-name",
      name,
      "--node-type",
      nodes_type(),
      "--nodes",
      nodes_size(),
      "--nodes-min",
      nodes_min_size(),
      "--nodes-max",
      nodes_max_size(),
      "--node-ami",
      "auto"
    ]

    args = if region(), do: args ++ ["--region", region()], else: args

    "eksctl"
    |> System.find_executable()
    |> Ops.Shells.Exec.call(args, [{:line, 4096}], false)
    |> handle_status_create_cluster()
  end

  defp handle_status_create_cluster(0), do: nil

  defp handle_status_create_cluster(status) do
    Ops.Utils.Io.puts(
      "If you have problem with availability zones on us-east-1, please restart command, or add region to config"
    )

    Ops.Shells.Exec.process_exit(status)
  end
end
