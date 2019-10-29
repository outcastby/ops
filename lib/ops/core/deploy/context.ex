defmodule Ops.Deploy.Context do
  defstruct [:env_name, :tag, :version, :prev_tag, :prev_version, args: []]

  def init("prod", tag) do
    version = Ops.Utils.Git.parse_tag_version(tag)
    {prev_version, prev_tag} = current_server_state("prod")

    %__MODULE__{version: version, prev_version: prev_version, tag: tag, prev_tag: prev_tag, env_name: "prod"}
  end

  def init(env_name, tag), do: %__MODULE__{tag: tag, env_name: env_name}

  def current_server_state(env_name) do
    skip_versions = Ops.Utils.Config.settings()[:skip_versions_of_containers] || false

    with :ok <- skip_versions(skip_versions),
         {:ok, path} <- build_args(env_name),
         {:ok, image} <- server_image(path) do
      {Ops.Utils.Git.parse_tag_version(image), image |> String.split(":") |> List.last()}
    else
      _ -> {nil, nil}
    end
  end

  def skip_versions(true), do: :error
  def skip_versions(false), do: :ok

  def build_args(env_name) do
    case Ops.Utils.Config.settings()[:build_info][:server_path] do
      nil -> :error
      path -> {:ok, String.replace(path, ":env_name:", env_name)}
    end
  end

  def server_image(path) do
    case "curl" |> System.find_executable() |> Ops.Shells.System.call([path], true) do
      nil -> :error
      response -> {:ok, response["image"]["name"]}
    end
  end
end
