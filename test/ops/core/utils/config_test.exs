defmodule Ops.Utils.ConfigTest do
  use ExUnit.Case
  import Mock

  setup_with_mocks([{Ops.Utils.Git, [:passthrough], [lookup_image_tag: fn -> "fake_branch_fake_version" end]}]) do
    :ok
  end

  describe "Utils.Config" do
    test "lookup_image_repository" do
      image_repository = Ops.Utils.Config.lookup_image_repository()
      assert image_repository == "my_company/repo_name"
    end

    test "lookup_available_commands" do
      available_commands = Ops.Utils.Config.lookup_available_commands()
      assert available_commands == ["staging", "uat", "prod", "stable", "build"]
    end

    test "lookup_built_depends" do
      built_depends = Ops.Utils.Config.lookup_built_depends()
      assert built_depends == ["staging", "uat", "prod", "stable"]
    end

    test "lookup_built_branches" do
      built_branches = Ops.Utils.Config.lookup_built_branches()
      assert built_branches == ["develop", "dev", "master", "release", "hotfix"]
    end

    test "lookup_image_name" do
      image_name_with_tag = Ops.Utils.Config.lookup_image_name("master-v0.2.0")
      assert image_name_with_tag == "my_company/repo_name:master-v0.2.0"

      image_name = Ops.Utils.Config.lookup_image_name()
      assert image_name == "my_company/repo_name:fake_branch_fake_version"
    end
  end
end
