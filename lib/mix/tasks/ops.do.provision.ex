defmodule Mix.Tasks.Ops.Do.Provision do
  use Mix.Task
  require IEx
  require Logger
  alias Ops.Utils.Io
  alias Ops.Utils.Do

  def run([env_name]) do
    if env_name =~ "_", do: raise("Env name should not have _ and other specific symbols")

    HTTPoison.start()
    Io.puts("Provision new environment #{env_name}")

    %{cluster_id: cluster_id, dir_path: dir_path} =
      env_name
      |> create_cluster()
      |> await_when_cluster_is_run()
      |> create_cluster_config_file()
      |> create_load_balancer_file()
      |> start_provision()

    Io.puts("

      # 1. DO Load Balancers. Get EXTERNAL-IP for 'p.2'. https://cloud.digitalocean.com/networking/load_balancers?i=f508b9&preserveScrollPosition=true

        kubectl --kubeconfig=\"tmp/#{env_name}-kubeconfig.yml\" get svc --namespace=ingress-nginx


      # 2. Route 53. Add DNS https://console.aws.amazon.com/route53/home
      # Urls:

        arcade.#{env_name}
        admin.arcade.#{env_name}

      # 3. Lambda. Add new object to environments. https://console.aws.amazon.com/lambda/home
      # Dont forget to save and test new lambda script

        {\"name\": \"#{env_name}\", \"cluster_id\": \"#{cluster_id}\"},


      # 4. Complete setup letsencrypt (Correct path to your prod_issuer.yml, see https://docs.cert-manager.io/en/latest/getting-started/install/kubernetes.html)
        kubectl --kubeconfig=\"tmp/#{env_name}-kubeconfig.yml\" apply --validate=false -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.11/deploy/manifests/00-crds.yaml
        kubectl --kubeconfig=\"tmp/#{env_name}-kubeconfig.yml\" create namespace cert-manager
        KUBECONFIG=#{dir_path}/tmp/#{env_name}-kubeconfig.yml helm repo add jetstack https://charts.jetstack.io
        KUBECONFIG=#{dir_path}/tmp/#{env_name}-kubeconfig.yml helm repo update
        KUBECONFIG=#{dir_path}/tmp/#{env_name}-kubeconfig.yml helm install --name cert-manager --namespace cert-manager --version v0.11.0 jetstack/cert-manager
        kubectl --kubeconfig=\"tmp/#{env_name}-kubeconfig.yml\" create -f devops/k8s/letsencrypt/prod_issuer.yml


      # 5. Deploy arcade, challenge, dashboard

        mix ops.deploy #{env_name}

      # 6. Enable proxy protocol if necessary!!! (optional)
        Open Load Balancer page https://cloud.digitalocean.com/networking/load_balancers?i=f508b9&preserveScrollPosition=true,
        find balancer by IP for current environment (ip from previous item), click More -> Edit settings -> Set Proxy Protocol to 'enabled'

        kubectl --kubeconfig=\"tmp/#{env_name}-kubeconfig.yml\" apply -f devops/k8s/ingress/ingress-nginx-config-map.yml

        And uncomment annotation for proxy in \"tmp/#{env_name}-load-balancer.yml\" and apply this file

        kubectl --kubeconfig=\"tmp/#{env_name}-kubeconfig.yml\" apply -f tmp/#{env_name}-load-balancer.yml
")
  end

  def start_provision(context) do
    args = ["-i", "inventory", "provision.yml", "--extra-vars", Ops.Provisions.BuildVars.call(:do, context)]
    "ansible-playbook" |> System.find_executable() |> Ops.Shells.Exec.call(args, [{:line, 4096}])
    context
  end

  def create_cluster(env_name),
    do: %{cluster_id: Do.create_cluster(env_name), env_name: env_name, dir_path: Ops.Shells.System.call("pwd")}

  def create_cluster_config_file(%{cluster_id: cluster_id, env_name: env_name} = context) do
    Ops.Provisions.CreateFile.call(:config, env_name, Do.get_cluster_config(cluster_id))
    context
  end

  def create_load_balancer_file(%{env_name: env_name} = context) do
    yaml = """
    kind: Service
    apiVersion: v1
    metadata:
      name: ingress-nginx
      namespace: ingress-nginx
      labels:
        app.kubernetes.io/name: ingress-nginx
        app.kubernetes.io/part-of: ingress-nginx
      #annotations:
        #service.beta.kubernetes.io/do-loadbalancer-enable-proxy-protocol: "true"
    spec:
      externalTrafficPolicy: Local
      type: LoadBalancer
      selector:
        app.kubernetes.io/name: ingress-nginx
        app.kubernetes.io/part-of: ingress-nginx
      ports:
        - name: http
          port: 80
          targetPort: http
        - name: https
          port: 443
          targetPort: https
    ---
    """

    Ops.Provisions.CreateFile.call(:load_balancer, env_name, yaml)
    context
  end

  def await_when_cluster_is_run(%{cluster_id: cluster_id, env_name: env_name} = context) do
    unless cluster_id |> Do.get_cluster_by_id() |> cluster_is_run?(env_name) do
      sleep(30)
      await_when_cluster_is_run(context)
    end

    Io.puts("\n[#{cluster_id}] Cluster is run")
    context
  end

  def cluster_is_run?(%{"node_pools" => node_pools} = cluster, env_name) do
    get_in(cluster, ["status", "state"]) == "running" &&
      node_pools
      |> Enum.find(&(&1["name"] == "#{env_name}-worker"))
      |> get_in(["nodes"])
      |> Enum.all?(&(get_in(&1, ["status", "state"]) == "running"))
  end

  def sleep(time) do
    Enum.each(1..time, fn _sec ->
      :timer.sleep(1000)
      Io.write(".")
    end)
  end
end
