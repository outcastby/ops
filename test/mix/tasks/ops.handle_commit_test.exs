defmodule Mix.Tasks.Ops.HandleCommitTest do
  use ExUnit.Case
  import Mock

  setup_with_mocks([
    {Mix.Tasks.Ops.Build, [:passthrough], [run: fn _ -> nil end]},
    {Mix.Tasks.Ops.Deploy, [:passthrough], [run: fn _ -> nil end]},
    {Mix.Tasks.Ops.Deploy, [:passthrough], [run: fn _ -> nil end]},
    {Ops.Utils.Io, [], [puts: fn _ -> "" end]}
  ]) do
    :ok
  end

  describe ".run" do
    test "handle build command" do
      with_mocks([
        {Ops.Utils.Git, [:passthrough], [lookup_commit_message_last_row: fn -> "build" end]}
      ]) do
        Mix.Tasks.Ops.HandleCommit.run([])
        assert called(Mix.Tasks.Ops.Build.run(:_))
      end
    end

    test "handle deploy command (staging)" do
      with_mocks([
        {Ops.Utils.Git, [:passthrough], [lookup_commit_message_last_row: fn -> "build/staging" end]}
      ]) do
        Mix.Tasks.Ops.HandleCommit.run([])
        assert called(Mix.Tasks.Ops.Deploy.run(["staging"]))
      end
    end

    test "handle deploy command (uat fast)" do
      with_mocks([
        {Ops.Utils.Git, [:passthrough], [lookup_commit_message_last_row: fn -> "build/uat~-f" end]}
      ]) do
        Mix.Tasks.Ops.HandleCommit.run([])
        assert called(Mix.Tasks.Ops.Deploy.run(["uat", "-f"]))
      end
    end

    test "if prod skip command deploy" do
      with_mocks([
        {Ops.Utils.Git, [:passthrough], [lookup_commit_message_last_row: fn -> "prod" end]}
      ]) do
        Mix.Tasks.Ops.HandleCommit.run([])
        refute called(Mix.Tasks.Ops.Deploy.run(["prod"]))
      end
    end
  end
end
