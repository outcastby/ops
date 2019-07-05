defmodule Mix.Tasks.Ops.Destroy do
  use Mix.Task

  def run([env_name, image_tag]) do
    Ops.Utils.Io.puts("Destroy service #{Mix.Project.config()[:app]}. Environment=#{env_name}. Image=#{image_tag}")

    args = [
      "-i",
      "inventory",
      "playbook_destroy.yml",
      "--extra-vars",
      "env_name=#{env_name} image_tag=#{image_tag} version=#{Ops.Utils.Git.parse_tag_version(image_tag)}"
    ]

    "ansible-playbook" |> System.find_executable() |> Ops.Shells.Exec.call(args, [{:line, 4096}])
  end
end
