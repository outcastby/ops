defmodule Ops.Provisions.BuildVars do
  def call(stage, context), do: (vars(stage, context) ++ docker_vars()) |> Enum.join(" ")

  defp vars(:aws, %{
         dir_path: dir_path,
         env_name: env_name,
         cluster_name: cluster_name,
         endpoint: endpoint,
         certificate_authority: certificate_authority
       }),
       do: [
         "env_name=#{env_name}",
         "dir_path=#{dir_path}",
         "cluster_name=#{cluster_name}",
         "endpoint=#{endpoint}",
         "certificate_authority=#{certificate_authority}"
       ]

  defp vars(:do, %{env_name: env_name, dir_path: dir_path}), do: ["env_name=#{env_name}", "dir_path=#{dir_path}"]

  defp docker_vars() do
    docker = Ops.Utils.Config.settings()[:docker]
    ["docker_user=#{docker[:username]}", "docker_pass=#{docker[:password]}", "docker_email=#{docker[:email]}"]
  end
end
