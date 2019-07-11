# Ops

###Description
Used for build docker containers, check commit messsage for start commands automatically, deploy docker containers to kubernetes cluster, support old and new versions containers.

###Requirements
1. Ansible
2. Docker
3. Kubernetes

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
  do_access_token: "token",
]
```

Description params:
- docker[username] - docker hub user (for push build)
- docker[password] - docker hub password
- docker[image_repository] - docker repository name (my_company/repo_name)
- docker[file] - path to docker file in current project (if file inside directory config 'config/dockerfile')
- build_info[file_name] - build info file name (info about last commit and version, example build_file.json)
- build_info[server_path] - path on server for file info (example, https://example.com/info), used for start many versions of backend
- available_environments - available environments for deploy on this environment server
- auto_build_branches - branches which create docker build automatically
- do_access_token - token for digital ocean(if use do cluster)
- slack[token] - token for slack, if you want send notification of start and end deploy
- slack[channel] - slack channel, where messages are sent
- check_restart_timeout - [OPTIONAL (default 30s)] timeout between get list containers(pods)

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
