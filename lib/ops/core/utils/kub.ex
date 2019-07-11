defmodule Ops.Utils.Kub do
  require IEx

  def options(env_name), do: %{url_params: %{base_url: get_url(env_name), token: get_token(env_name)}}

  def config_file(env_name), do: "--kubeconfig=tmp/#{env_name}-kubeconfig.yml"

  def get_url(env_name),
    do:
      Ops.Shells.System.call("kubectl", [
        config_file(env_name),
        "config",
        "view",
        "--minify",
        "-o",
        "jsonpath={.clusters[0].cluster.server}"
      ])

  def get_token(env_name) do
    acc =
      Ops.Shells.System.call("kubectl", [
        config_file(env_name),
        "get",
        "serviceaccount",
        "default",
        "-o",
        "jsonpath={.secrets[0].name}"
      ])

    "kubectl"
    |> Ops.Shells.System.call([config_file(env_name), "get", "secret", acc, "-o", "jsonpath={.data.token}"])
    |> Base.decode64!()
  end

  def base_request(%{url_params: %{token: token}} = options),
    do: %Sdk.Request{headers: [{"Authorization", "Bearer #{token}"}], options: options}

  def get_containers(options, name) do
    options
    |> base_request()
    |> Ops.Sdk.Kub.Client.pods()
    |> handle_ok_response()
    |> get_in(["items"])
    |> Enum.filter(&(&1["metadata"]["labels"]["app"] == name))
  end

  def get_image(options, name) do
    options
    |> put_in([:url_params, :name], name)
    |> base_request()
    |> Ops.Sdk.Kub.Client.deployment()
    |> handle_ok_response()
    |> get_in(["spec", "template", "spec", "containers"])
    |> find_container_image(name)
  end

  def find_container_image(containers, name),
    do: containers |> Enum.find(&(&1["name"] == name)) |> get_in(["image"])

  def handle_ok_response({:ok, result}), do: result
end
