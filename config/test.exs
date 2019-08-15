use Mix.Config

config :ops, :ops,
  docker: [
    username: "docker_user",
    password: "docker_pass",
    image_repository: "my_company/repo_name",
    file: "config/dockerfile"
  ],
  slack: [
    token: "slack_token",
    channel: "slack_channel"
  ],
  check_restart_timeout: 1,
  available_environments: ["staging", "uat", "prod", "stable"],
  auto_build_branches: ["develop", "dev", "master", "release", "hotfix"],
  prefix_for_clusters: "gm",
  path_to_cluster_cert: "tmp",
  aws_configuration: [
    region: "us-east-1",
    nodes_type: "c5.large",
    nodes_size: 2,
    nodes_min_size: 2,
    nodes_max_size: 2
  ],
  do_configuration: [
    access_token: "token",
    region: "fra1",
    nodes_type: "s-2vcpu-4gb",
    nodes_size: 2,
    manager_type: "s-1vcpu-2gb"
  ]
