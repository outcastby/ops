defmodule Ops.Deploy.FindOrCreateBuildTest do
  use ExUnit.Case
  import Mock

  test ".call" do
    with_mocks([
      {Ops.Sdk.DockerHub.Client, [], [tag_info: fn _ -> {:ok, ""} end]},
      {Ops.Sdk.DockerHub.Client, [], [user_login: fn _ -> {:ok, %{"token" => "fake"}} end]},
      {Ops.Utils.Io, [], [puts: fn _ -> "" end]}
    ]) do
      result =
        %Ops.Deploy.Context{
          version: nil,
          prev_version: nil,
          tag: "develop-test",
          prev_tag: nil,
          env_name: "uat"
        }
        |> Ops.Deploy.FindOrCreateBuild.call()

      assert result == %Ops.Deploy.Context{
               version: nil,
               prev_version: nil,
               tag: "develop-test",
               prev_tag: nil,
               env_name: "uat"
             }
    end
  end
end
