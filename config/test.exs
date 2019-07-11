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
  do_access_token: "token"
