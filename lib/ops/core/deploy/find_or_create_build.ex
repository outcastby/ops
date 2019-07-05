defmodule Ops.Deploy.FindOrCreateBuild do
  def call(%{tag: tag} = context) do
    repository = Ops.Utils.Config.lookup_image_repository()
    Ops.Utils.Io.puts("Check if build exist #{Mix.Project.config()[:app]}. Repository=#{repository} ImageTag=#{tag}")

    request = %Sdk.Request{
      headers: [{"Authorization", "JWT #{get_docker_hub_token()}"}],
      options: %{url_params: %{repository: repository, tag: tag}}
    }

    case Ops.Sdk.DockerHub.Client.tag_info(request) do
      {:ok, _} -> Ops.Utils.Io.puts("Exist ImageTag=#{tag}")
      _ -> Mix.Tasks.Ops.Build.run([tag])
    end

    context
  end

  def get_docker_hub_token() do
    request = %Sdk.Request{
      payload: Ops.Utils.Config.settings()[:docker] |> Enum.into(%{}) |> Map.take([:username, :password])
    }

    {:ok, %{"token" => token}} = Ops.Sdk.DockerHub.Client.user_login(request)
    token
  end
end
