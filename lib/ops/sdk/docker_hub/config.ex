defmodule Ops.Sdk.DockerHub.Config do
  def data,
    do: %{
      base_url: "https://hub.docker.com/v2",
      sdk_name: "Docker Hub",
      endpoints: %{
        user_login: %{
          type: :post,
          url: "/users/login"
        },
        tag_info: %{
          type: :get,
          url: &"/repositories/#{&1.repository}/tags/#{&1.tag}/"
        }
      }
    }
end
