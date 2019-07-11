defmodule Mix.Tasks.Ops.Deploy do
  use Mix.Task
  alias Ops.Deploy

  def run([env_name]), do: run([env_name, Ops.Utils.Git.lookup_image_tag(), false])

  def run([env_name, x]) when x == "-f", do: run([env_name, Ops.Utils.Git.lookup_image_tag(), x])

  def run([env_name, image_tag]), do: run([env_name, image_tag, false])

  def run([env_name, image_tag, "-f"]), do: run([env_name, image_tag, true])

  def run([env_name, image_tag, is_fast]) do
    HTTPoison.start()
    Ops.Utils.Io.puts("Deploy service #{Mix.Project.config()[:app]}. Environment=#{env_name}. Image=#{image_tag}")

    env_name
    |> Deploy.Context.init(image_tag)
    |> Deploy.BuildArgs.call(is_fast)
    |> Deploy.FindOrCreateBuild.call()
    |> Deploy.SendSlackNotification.call(:before)
    |> Deploy.Process.call()
  end
end
