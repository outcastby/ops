# Ops

###Description
Used for build docker containers, check commit messsage for start commands automatically, deploy docker containers to kubernetes cluster, support old and new versions containers.

###Requirements
1. Ansible
2. Docker
3. Kubernetes
4. aws cli (If you use amazon, see https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
5. eksctl cli (If you use amazon, see https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html)

## Installation

```elixir
def deps do
  [{:ops, "~> 0.1.0"}]
end
```

#### Configuration

The default behaviour is to configure using the application environment:

In `config/config.exs`, add:

```elixir
config :my_app, :ops, [
  docker: [
    username:  "docker_user",
    password: "docker_pass",
    email: "docker_email",
    image_repository: "my_company/repo_name",
    file: "config/dockerfile"
  ],
  slack: [
    token: "slack_token",
    channel: "slack_channel"
  ],
  build_info: [
    file_name: "build_file.json",
    server_path: "https://example.com/info"
  ],
  check_restart_timeout: 30,
  available_environments: ["staging", "uat", "prod", "stable"],
  auto_build_branches: ["develop", "dev", "master", "release", "hotfix"],
  skip_versions_of_containers: true,
  path_to_cluster_cert: "tmp",
  prefix_for_clusters: "gm",
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
    manager_type: "s-1vcpu-2gb",
    cluster_version: "1.14.5-do.0"
  ]
]
```

Description params:
- docker[username] - docker hub user (for push build)
- docker[password] - docker hub password
- docker[email] - docker hub email (use for create secrets, for pull private repository)
- docker[image_repository] - docker repository name (my_company/repo_name)
- docker[file] - path to docker file in current project (if file inside directory config 'config/dockerfile')
- build_info[file_name] - build info file name (info about last commit and version, example build_file.json)
- build_info[server_path] - path on server for file info (example, https://example.com/info), used for start many versions of backend
- available_environments - available environments for deploy on this environment server
- auto_build_branches - branches which create docker build automatically
- slack[token] - token for slack, if you want send notification of start and end deploy
- slack[channel] - slack channel, where messages are sent
- check_restart_timeout - [OPTIONAL (default 30s)] timeout between get list containers(pods)
- skip_versions_of_containers - [OPTIONAL (default false)] skip logic create containers with prev and current versions, available only current version
- prefix_for_clusters - [OPTIONAL (default gm)] prefix of name for cluster
- path_to_cluster_cert - [OPTIONAL (default tmp)] path to cluster kube config file
- do_configuration[access_token] - token for digital ocean(if use do cluster)
- do_configuration[region] - [OPTIONAL (default fra1)] cluster region
- do_configuration[nodes_type] - [OPTIONAL (default s-2vcpu-4gb)] type of worker nodes
- do_configuration[nodes_size] - [OPTIONAL (default 2)] count of worker nodes
- do_configuration[manager_type] - [OPTIONAL (default s-1vcpu-2gb)] type of manager node
- do_configuration[cluster_version] - [OPTIONAL (default 1.14.5-do.0)] version of kubernetes cluster, set this parameter if a version is expired
- aws_configuration[region] - [OPTIONAL (default like in aws client)] cluster region
- aws_configuration[nodes_type] - [OPTIONAL (default c5.large)] type of worker nodes
- aws_configuration[nodes_size] - [OPTIONAL (default 2)] count of worker nodes
- aws_configuration[nodes_min_size] - [OPTIONAL (default 2)] count of worker nodes min size
- aws_configuration[nodes_max_size] - [OPTIONAL (default 2)] count of worker nodes max size
- aws_configuration[nodes_max_size] - [OPTIONAL (default 2)] count of worker nodes max size

#### Examples

Deploy commands:
 - mix ops.deploy staging
 - mix ops.deploy uat
 - mix ops.deploy uat -f (skip migrations in job command)
 
Build command:
 - mix ops.build
 - mix ops.build v.10202
 
Destroy containers by version:
 - mix ops.destroy v0.1.0
 
Fetch certificate:
 - mix ops.fetch uat
 
Start commands from last commit, if in last row on commit set command "build" and commands from available_environments, we handle this commands in deploy or build, "build" command available as default.
Examples last row in commit message:
 - build (only build)
 - staging (build and deploy to staging)
 - uat/staging (build and deploy to uat and staging)
 - uat~-f/staging (build and deploy to uat without migration job and staging)
 
 Example full commit message
 
 ----------------------------
 Add new variable
 
 staging
 ____________________________
