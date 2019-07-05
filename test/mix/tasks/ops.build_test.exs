defmodule Mix.Tasks.Ops.BuildTest do
  use ExUnit.Case
  import Mock

  setup_with_mocks([
    {Ops.Shells.Exec, [:passthrough], [call: fn _, _, _ -> "" end]},
    {Ops.Utils.Io, [:passthrough], [puts: fn _ -> "" end]},
    {Ops.Shells.System, [:passthrough],
     [
       call: fn
         _, ["symbolic-ref", "--short", "-q", "HEAD"] -> "master"
         _, ["tag", "-l", "--sort=v:refname"] -> "v0.1.0"
         _, ["log", "-1", "--format=%at"] -> "1562590744"
         _, _ -> ""
       end
     ]},
    {File, [:passthrough], [write: fn _, _ -> "" end]}
  ]) do
    :ok
  end

  describe ".run" do
    test "without build info file" do
      result = Mix.Tasks.Ops.Build.run([])
      assert result == "my_company/repo_name:master-v0.1.0"
      refute called(File.write(:_, :_))
    end

    test "with build info file" do
      with_mocks([
        {Ops.Utils.Config, [:passthrough],
         [
           settings: fn ->
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
         ]}
      ]) do
        result = Mix.Tasks.Ops.Build.run([])
        assert result == "my_company/repo_name:master-v0.1.0"
        assert called(File.write(:_, :_))
      end
    end
  end
end
