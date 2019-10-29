defmodule Ops.Deploy.ContextTest do
  use ExUnit.Case
  import Mock

  describe ".init()" do
    test "uat environment" do
      result = Ops.Deploy.Context.init("uat", "test_tag")

      assert result == %Ops.Deploy.Context{
               tag: "test_tag",
               env_name: "uat",
               version: nil,
               prev_tag: nil,
               prev_version: nil,
               args: []
             }
    end

    test "prod environment without build_info server_path" do
      with_mocks([
        {Ops.Shells.System, [:passthrough], [call: fn _, _ -> "{\"image\": {\"name\": \"master-v0.1.0\"}}" end]},
        {String, [:passthrough], [replace: fn _, _, _ -> "" end]}
      ]) do
        result = Ops.Deploy.Context.init("prod", "master-v0.2.0")

        assert result == %Ops.Deploy.Context{
                 env_name: "prod",
                 tag: "master-v0.2.0",
                 version: "v0.2",
                 prev_tag: nil,
                 prev_version: nil,
                 args: []
               }
      end
    end

    test "prod environment with build_info server_path" do
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
               do_configuration: [access_token: "token"]
             ]
           end
         ]},
        {Ops.Shells.System, [:passthrough], [call: fn _, _, _ -> %{"image" => %{"name" => "master-v0.1.0"}} end]},
        {String, [:passthrough], [replace: fn _, _, _ -> "" end]}
      ]) do
        result = Ops.Deploy.Context.init("prod", "master-v0.2.0")

        assert result == %Ops.Deploy.Context{
                 env_name: "prod",
                 tag: "master-v0.2.0",
                 version: "v0.2",
                 prev_tag: "master-v0.1.0",
                 prev_version: "v0.1",
                 args: []
               }
      end
    end
  end

  describe ".current_server_state" do
    test "prod environment with versions" do
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
               do_configuration: [access_token: "token"]
             ]
           end
         ]},
        {Ops.Shells.System, [:passthrough], [call: fn _, _, _ -> %{"image" => %{"name" => "master-v0.1.0"}} end]}
      ]) do
        result = Ops.Deploy.Context.current_server_state("prod")
        assert result == {"v0.1", "master-v0.1.0"}
      end
    end

    test "prod environment without versions" do
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
               do_configuration: [access_token: "token"],
               skip_versions_of_containers: true
             ]
           end
         ]},
        {Ops.Shells.System, [:passthrough], [call: fn _, _ -> "{\"image\": {\"name\": \"master-v0.1.0\"}}" end]}
      ]) do
        result = Ops.Deploy.Context.current_server_state("prod")
        assert result == {nil, nil}
      end
    end
  end
end
