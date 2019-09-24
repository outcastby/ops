defmodule Ops.Utils.Do do
  require IEx
  require Logger
  alias Ops.Utils.Io

  @prefix "gm"
  @region "fra1"
  @nodes_type "s-2vcpu-4gb"
  @nodes_size 2
  @manager_type "s-1vcpu-2gb"
  @cluster_version "1.14.5-do.0"

  def prefix(), do: Ops.Utils.Config.settings()[:prefix_for_clusters] || @prefix
  def region(), do: Ops.Utils.Config.settings()[:do_configuration][:region] || @region
  def nodes_type(), do: Ops.Utils.Config.settings()[:do_configuration][:nodes_type] || @nodes_type
  def nodes_size(), do: Ops.Utils.Config.settings()[:do_configuration][:nodes_size] || @nodes_size
  def manager_type(), do: Ops.Utils.Config.settings()[:do_configuration][:manager_type] || @manager_type
  def cluster_version(), do: Ops.Utils.Config.settings()[:do_configuration][:cluster_version] || @cluster_version

  def create_cluster(env_name) do
    request = %SDK.Request{
      payload: %{
        name: "#{prefix()}-#{env_name}",
        region: region(),
        version: cluster_version(),
        tags: [env_name],
        node_pools: [
          %{size: nodes_type(), count: nodes_size(), name: "#{env_name}-worker", tags: ["servers", "worker"]},
          %{size: manager_type(), count: 1, name: "manager", tags: ["manager"]}
        ]
      }
    }

    response = request |> Ops.SDK.Do.Client.create_cluster() |> handle_create()
    Io.puts("Creating cluster: response is #{inspect(response)}")

    %{"kubernetes_cluster" => %{"id" => cluster_id}} = response

    Io.puts(
      "[#{cluster_id}] Cluster is provisioning. Please wait about 1-2 minutes.\n More details: https://cloud.digitalocean.com/kubernetes/clusters"
    )

    Io.puts("\n[#{cluster_id}] Cluster setup. It might take 2+ minutes")
    cluster_id
  end

  def handle_create(response) do
    case response do
      {:ok, body} ->
        body

      {:error, body} ->
        Logger.warn("An error occurred while creating the cluster, with the message - #{inspect(body)}")

        Io.puts(
          "If you have error with version slug, check available versions of cluster and change in config parameter 'cluster_version' (see version in dropdown on this page https://cloud.digitalocean.com/kubernetes/clusters/new)"
        )

        exit("An error occurred while creating the cluster")
    end
  end

  def get_clusters() do
    {:ok, %{"kubernetes_clusters" => clusters}} = Ops.SDK.Do.Client.clusters(%SDK.Request{})
    clusters
  end

  def get_cluster_by_id(cluster_id), do: Enum.find(get_clusters(), &(&1["id"] == cluster_id))

  def get_cluster_config(cluster_id) do
    {:ok, body} = Ops.SDK.Do.Client.cluster_config(%SDK.Request{options: %{url_params: %{cluster_id: cluster_id}}})
    body
  end
end
