defmodule Mix.Tasks.Ops.Aws.Provision do
  use Mix.Task
  require IEx
  alias Ops.Utils.Io
  alias Ops.Utils.Aws

  @prefix Ops.Utils.Config.settings()[:prefix_for_clusters] || "gm"

  def run([env_name]) do
    if env_name =~ "_", do: raise("Env name should not have _ and other specific symbols")

    HTTPoison.start()
    Io.puts("Provision AWS environment #{env_name}")

    %{dir_path: dir_path} =
      env_name
      |> valid_user?()
      |> find_or_create_cluster_and_nodes()
      |> add_context_cluster_config()
      |> create_cluster_config_file()
      |> create_load_balancer_file()
      |> start_provision()

    Io.puts("

      # 1. Load Balancers. Get EXTERNAL-IP for 'p.2'.

        kubectl --kubeconfig=\"tmp/#{env_name}-kubeconfig.yml\" get svc --namespace=ingress-nginx

      # 2. Route 53. Add DNS https://console.aws.amazon.com/route53/home
      # Urls:

        arcade.#{env_name}
        admin.arcade.#{env_name}

      # 3. Lambda. Add new object to environments. https://console.aws.amazon.com/lambda/home?region=us-east-1#/functions/s3-amazon-kub?tab=graph
      # Dont forget to save and test new lambda script

        {\"name\": \"#{env_name}\", \"cluster_name\": \"#{@prefix}-#{env_name}\"},


      # 4. Complete setup letsencrypt

        KUBECONFIG=#{dir_path}/tmp/#{env_name}-kubeconfig.yml helm install --name cert-manager --namespace kube-system stable/cert-manager --version v0.5.2
        kubectl --kubeconfig=\"tmp/#{env_name}-kubeconfig.yml\" create -f devops/k8s/letsencrypt/prod_issuer.yml


      # 5. Deploy arcade, challenge, dashboard

        mix ops.deploy #{env_name}

      # 6. Enable proxy protocol, if necessary!!! (optional)
        (see, https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-proxy-protocol.html)

        kubectl --kubeconfig=\"tmp/#{env_name}-kubeconfig.yml\" apply -f devops/k8s/ingress/ingress-nginx-config-map.yml

")
  end

  def valid_user?(env_name) do
    # check if user is admin
    unless Aws.get_user_group_by_name("Admin"), do: exit("Your aws user is not admin")
    env_name
  end

  def find_or_create_cluster_and_nodes(env_name) do
    name = "#{@prefix}-#{env_name}"
    "eksctl-#{name}-cluster" |> Aws.get_stack_by_name() |> create_cluster(name)
    env_name
  end

  def create_cluster(nil, name), do: Aws.create_cluster_and_nodes(name)

  def create_cluster(%{"StackStatus" => status, "StackName" => stack_name}, name) when status != "CREATE_COMPLETE" do
    Aws.delete_stack(stack_name)
    Aws.create_cluster_and_nodes(name)
  end

  def create_cluster(_, _), do: nil

  def add_context_cluster_config(env_name) do
    name = "#{@prefix}-#{env_name}"
    cluster = Aws.get_cluster_by_name(name)

    %{
      env_name: env_name,
      dir_path: Ops.Shells.System.call("pwd"),
      cluster_name: name,
      endpoint: cluster["endpoint"],
      certificate_authority: get_in(cluster, ["certificateAuthority", "data"])
    }
  end

  def create_cluster_config_file(
        %{
          env_name: env_name,
          cluster_name: cluster_name,
          endpoint: endpoint,
          certificate_authority: certificate_authority
        } = context
      ) do
    yaml = """
    apiVersion: v1
    clusters:
    - cluster:
        certificate-authority-data: #{certificate_authority}
        server: #{endpoint}
      name: aws
    contexts:
    - context:
        cluster: aws
        user: aws
      name: aws
    current-context: aws
    kind: Config
    preferences: {}
    users:
    - name: aws
      user:
        exec:
          apiVersion: client.authentication.k8s.io/v1alpha1
          args:
          - token
          - -i
          - #{cluster_name}
          command: aws-iam-authenticator
    """

    Ops.Provisions.CreateFile.call(:config, env_name, yaml)
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
      annotations:
        service.beta.kubernetes.io/aws-load-balancer-backend-protocol: tcp
        #service.beta.kubernetes.io/aws-load-balancer-ssl-cert: <arn>
        # Only run SSL on the port named "https" below.
        service.beta.kubernetes.io/aws-load-balancer-ssl-ports: https
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

  def start_provision(
        %{
          dir_path: dir_path,
          env_name: env_name,
          cluster_name: cluster_name,
          endpoint: endpoint,
          certificate_authority: certificate_authority
        } = context
      ) do
    args = [
      "-i",
      "inventory",
      "provision.yml",
      "--extra-vars",
      "
      env_name=#{env_name}
      dir_path=#{dir_path}
      cluster_name=#{cluster_name}
      endpoint=#{endpoint}
      certificate_authority=#{certificate_authority}
      "
    ]

    "ansible-playbook" |> System.find_executable() |> Ops.Shells.Exec.call(args, [{:line, 4096}])
    context
  end
end
