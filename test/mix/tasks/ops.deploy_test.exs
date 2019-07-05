defmodule Mix.Tasks.Ops.DeployTest do
  use ExUnit.Case
  import Mock

  setup_with_mocks([
    {Ops.Shells.Exec, [], [call: fn _, _, _ -> "" end]},
    {Ops.Sdk.DockerHub.Client, [], [tag_info: fn _ -> {:ok, ""} end]},
    {Ops.Sdk.DockerHub.Client, [], [user_login: fn _ -> {:ok, %{"token" => "fake"}} end]},
    {Ops.Utils.Io, [], [puts: fn _ -> "" end]}
  ]) do
    :ok
  end

  describe ".run" do
    test "start deploy uat without fast" do
      result = Mix.Tasks.Ops.Deploy.run(["uat", "develop-test"])

      assert result == %Ops.Deploy.Context{
               env_name: "uat",
               prev_tag: nil,
               prev_version: nil,
               tag: "develop-test",
               version: nil,
               args: [
                 "-i",
                 "inventory",
                 "playbook.yml",
                 "--extra-vars",
                 "env_name=uat image_tag=develop-test version= prev_image_tag= prev_version=",
                 "--skip-tags",
                 "release"
               ]
             }
    end

    test "start deploy uat with fast" do
      result = Mix.Tasks.Ops.Deploy.run(["uat", "develop-test", "-f"])

      assert result == %Ops.Deploy.Context{
               env_name: "uat",
               prev_tag: nil,
               prev_version: nil,
               tag: "develop-test",
               version: nil,
               args: [
                 "-i",
                 "inventory",
                 "playbook.yml",
                 "--extra-vars",
                 "env_name=uat image_tag=develop-test version= prev_image_tag= prev_version=",
                 "--skip-tags",
                 "release,job"
               ]
             }
    end

    test "start deploy prod" do
      with_mocks([
        {Application, [:passthrough],
         [
           get_env: fn _, _, _ ->
             [
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
               build_info: [
                 file_name: "build_file.json",
                 server_path: "https://example.com/info"
               ],
               available_environments: ["staging", "uat", "prod", "stable"],
               auto_build_branches: ["develop", "dev", "master", "release", "hotfix"],
               do_access_token: "token"
             ]
           end
         ]},
        {System, [],
         [
           cmd: fn _, _ -> {"{\"image\": {\"name\": \"master-v0.1.0\"}}", 0} end,
           find_executable: fn _ -> "" end,
           get_env: fn _ -> "" end
         ]},
        {Ops.Sdk.Slack.Client, [], [send: fn _ -> "" end]},
        {String, [:passthrough], [replace: fn _, _, _ -> "" end, split: fn _, _ -> ["master-v0.1.0"] end]}
      ]) do
        result = Mix.Tasks.Ops.Deploy.run(["prod", "master-v0.2.0"])

        assert result == %Ops.Deploy.Context{
                 env_name: "prod",
                 prev_tag: "master-v0.1.0",
                 prev_version: "v0.1",
                 tag: "master-v0.2.0",
                 version: "v0.2",
                 args: [
                   "-i",
                   "inventory",
                   "playbook.yml",
                   "--extra-vars",
                   "env_name=prod image_tag=master-v0.2.0 version=v0.2 prev_image_tag=master-v0.1.0 prev_version=v0.1"
                 ]
               }
      end
    end
  end
end
