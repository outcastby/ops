defmodule Ops.Deploy.BuildArgsTest do
  use ExUnit.Case
  import Mock

  setup_with_mocks([{Ops.Utils.Io, [], [puts: fn _ -> "" end]}]) do
    :ok
  end

  describe ".call" do
    test "test with skip tag release" do
      result =
        Ops.Deploy.BuildArgs.call(
          %Ops.Deploy.Context{
            version: nil,
            prev_version: nil,
            tag: "develop-test",
            prev_tag: nil,
            env_name: "uat"
          },
          false
        )

      assert result == %Ops.Deploy.Context{
               args: [
                 "-i",
                 "inventory",
                 "playbook.yml",
                 "--extra-vars",
                 "env_name=uat image_tag=develop-test version= prev_image_tag= prev_version= image_repository=my_company/repo_name",
                 "--skip-tags",
                 "fetch,release"
               ],
               env_name: "uat",
               prev_tag: nil,
               prev_version: nil,
               tag: "develop-test",
               version: nil
             }
    end

    test "test with skip tag release and job" do
      result =
        Ops.Deploy.BuildArgs.call(
          %Ops.Deploy.Context{
            version: nil,
            prev_version: nil,
            tag: "develop-test",
            prev_tag: nil,
            env_name: "uat"
          },
          true
        )

      assert result == %Ops.Deploy.Context{
               args: [
                 "-i",
                 "inventory",
                 "playbook.yml",
                 "--extra-vars",
                 "env_name=uat image_tag=develop-test version= prev_image_tag= prev_version= image_repository=my_company/repo_name",
                 "--skip-tags",
                 "fetch,release,job"
               ],
               env_name: "uat",
               prev_tag: nil,
               prev_version: nil,
               tag: "develop-test",
               version: nil
             }
    end

    test "test skip only tag job" do
      result =
        Ops.Deploy.BuildArgs.call(
          %Ops.Deploy.Context{
            version: "v0.2",
            prev_version: "v0.1",
            tag: "master-v0.2.0",
            prev_tag: "master-v0.1.0",
            env_name: "prod"
          },
          true
        )

      assert result == %Ops.Deploy.Context{
               args: [
                 "-i",
                 "inventory",
                 "playbook.yml",
                 "--extra-vars",
                 "env_name=prod image_tag=master-v0.2.0 version=v0.2 prev_image_tag=master-v0.1.0 prev_version=v0.1 image_repository=my_company/repo_name",
                 "--skip-tags",
                 "fetch,job"
               ],
               env_name: "prod",
               prev_tag: "master-v0.1.0",
               prev_version: "v0.1",
               tag: "master-v0.2.0",
               version: "v0.2"
             }
    end
  end
end
