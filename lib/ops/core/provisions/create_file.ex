defmodule Ops.Provisions.CreateFile do
  @path Ops.Utils.Config.settings()[:path_to_cluster_cert] || "tmp"

  def call(:config, env_name, body), do: File.write("#{@path}/#{env_name}-kubeconfig.yml", body)
  def call(:load_balancer, env_name, body), do: File.write("#{@path}/#{env_name}-load-balancer.yml", body)
end
