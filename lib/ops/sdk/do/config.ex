defmodule Ops.SDK.Do.Config do
  def data,
    do: %{
      base_url: "https://api.digitalocean.com/v2/kubernetes",
      sdk_name: "Digital Ocean",
      access_token: Ops.Utils.Config.settings()[:do_configuration][:access_token],
      endpoints: %{
        create_cluster: %{
          type: :post,
          url: "/clusters"
        },
        clusters: %{
          type: :get,
          url: "/clusters"
        },
        cluster_config: %{
          type: :get,
          url: &"/clusters/#{&1.cluster_id}/kubeconfig"
        }
      }
    }
end
