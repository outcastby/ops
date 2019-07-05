defmodule Ops.Commits.LookupCommandsTest do
  use ExUnit.Case

  describe ".call" do
    test "build message" do
      commands = Ops.Commits.LookupCommands.call("build")
      assert commands == [["build"]]
    end

    test "deploy message" do
      commands = Ops.Commits.LookupCommands.call("staging")
      assert commands == [["build"], ["staging"]]
    end

    test "multi deploy message" do
      commands = Ops.Commits.LookupCommands.call("staging/uat")
      assert commands == [["build"], ["staging"], ["uat"]]
    end

    test "multi deploy message, with parametr fast" do
      commands = Ops.Commits.LookupCommands.call("staging/uat~-f")
      assert commands == [["build"], ["staging"], ["uat", "-f"]]
    end
  end
end
