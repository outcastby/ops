defmodule Ops.Sdk.Do.Config do
  def data,
    do: %{
      base_url: "https://api.digitalocean.com/v2/kubernetes",
      sdk_name: "Digital Ocean",
      access_token: Ops.Utils.Config.settings()[:do_access_token],
      endpoints: %{
        create_cluster: %{
          type: :post,
          url: "/clusters"
        },
        clusters: %{
          type: :get,
          url: "/clusters"
        }
      }
    }
end
