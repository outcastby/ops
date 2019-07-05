defmodule Mix.Tasks.Ops.FetchCert do
  use Mix.Task

  def run([env_name]) do
    Ops.Utils.Io.puts("Fetch do cert for service #{Mix.Project.config()[:app]}. Environment=#{env_name}")
    args = ["-i", "inventory", "playbook.yml", "--extra-vars", "env_name=#{env_name}", "--tags", "fetch"]
    "ansible-playbook" |> System.find_executable() |> Ops.Shells.Exec.call(args, [{:line, 4096}])
  end
end
