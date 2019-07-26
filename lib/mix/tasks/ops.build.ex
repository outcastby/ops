defmodule Mix.Tasks.Ops.Build do
  use Mix.Task
  alias Ops.Utils

  @docker "docker"

  @doc false
  def run(args) do
    {Utils.Config.lookup_image_name(args && List.first(args)),
     Ops.Shells.System.call("git", ["symbolic-ref", "--short", "-q", "HEAD"])}
    |> put_in_console("Build service #{Mix.Project.config()[:app]}")
    |> put_in_console("Building '#{Mix.Project.config()[:app]}' branch is ':branch:'")
    |> put_in_console("Building '#{Mix.Project.config()[:app]}' Docker image as ':image_name:'")
    |> write_build_info_file(Utils.Config.settings()[:build_info][:file_name])
    |> build_docker_image()
    |> put_in_console("Pushing ':image_name:' image into registry")
    |> push_docker_image()
  end

  defp put_in_console({image_name, branch} = context, message) do
    message |> String.replace(":branch:", branch) |> String.replace(":image_name:", image_name) |> Utils.Io.puts()
    context
  end

  defp build_docker_image({image_name, _} = context) do
    @docker
    |> System.find_executable()
    |> Ops.Shells.Exec.call(["build", "-f", Utils.Config.settings()[:docker][:file], "-t", image_name, "."], [
      {:line, 4096}
    ])

    context
  end

  defp push_docker_image({image_name, _}) do
    @docker |> System.find_executable() |> Ops.Shells.Exec.call(["push", image_name], [{:line, 4096}])
    image_name
  end

  defp write_build_info_file(context, nil), do: context

  defp write_build_info_file({image_name, _} = context, file) do
    result =
      Poison.encode!(%{
        image: %{
          name: image_name,
          build_date: Timex.format!(Timex.now(), "{ANSIC}"),
          build_author: Ops.Shells.System.call("whoami")
        },
        commit: %{
          date: Utils.Git.commit_date(),
          message: Utils.Git.commit_message(),
          hash: Utils.Git.commit_hash(),
          author: Utils.Git.commit_author()
        }
      })

    File.write(file, result)
    context
  end
end
