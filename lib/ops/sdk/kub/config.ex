defmodule Ops.SDK.Kub.Config do
  def data,
    do: %{
      base_url: "",
      sdk_name: "Kubernetes cluster API",
      endpoints: %{
        pods: %{
          type: :get,
          url: &"#{&1.base_url}/api/v1/namespaces/default/pods"
        },
        deployment: %{
          type: :get,
          url: &"#{&1.base_url}/apis/apps/v1/namespaces/default/deployments/#{&1.name}"
        }
      }
    }
end
