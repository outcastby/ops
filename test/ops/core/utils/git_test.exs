defmodule Ops.Utils.GitTest do
  use ExUnit.Case
  import Mock

  describe "Utils.Git.lookup_image_tag" do
    test "branch master" do
      with_mocks([
        {Ops.Shells.System, [:passthrough],
         [
           call: fn
             _, ["symbolic-ref", "--short", "-q", "HEAD"] -> "master"
             _, ["tag", "-l", "--sort=v:refname"] -> "v0.1.0"
           end
         ]}
      ]) do
        tag = Ops.Utils.Git.lookup_image_tag()
        assert tag == "master-v0.1.0"
      end
    end

    test "branch develop" do
      with_mocks([
        {Ops.Shells.System, [:passthrough],
         [
           call: fn
             _, ["symbolic-ref", "--short", "-q", "HEAD"] -> "develop"
             _, ["log", "-1", "--format=%at"] -> "1562590744"
             _, ["rev-parse", "--short=7", "HEAD"] -> "jhsnna"
           end
         ]}
      ]) do
        tag = Ops.Utils.Git.lookup_image_tag()
        assert tag == "dev-jhsnna-08Jul"
      end
    end

    test "branch feacture/check-branch" do
      with_mocks([
        {Ops.Shells.System, [:passthrough],
         [
           call: fn
             _, ["symbolic-ref", "--short", "-q", "HEAD"] -> "feacture-check-branch"
             _, ["log", "-1", "--format=%at"] -> "1562590744"
             _, ["rev-parse", "--short=7", "HEAD"] -> "jhsnna"
           end
         ]}
      ]) do
        tag = Ops.Utils.Git.lookup_image_tag()
        assert tag == "feacture-check-branch-jhsnna-08Jul"
      end
    end
  end

  describe "Utils.Git.lookup_branch" do
    test "master" do
      with_mocks([{Ops.Shells.System, [:passthrough], [call: fn _, _ -> "master" end]}]) do
        branch = Ops.Utils.Git.lookup_branch()
        assert branch == "master"
      end
    end

    test "develop" do
      with_mocks([{Ops.Shells.System, [:passthrough], [call: fn _, _ -> "develop" end]}]) do
        branch = Ops.Utils.Git.lookup_branch()
        assert branch == "dev"
      end
    end

    test "feature/check" do
      with_mocks([{Ops.Shells.System, [:passthrough], [call: fn _, _ -> "feature/check" end]}]) do
        branch = Ops.Utils.Git.lookup_branch()
        assert branch == "feature-check"
      end
    end
  end

  describe "Utils.Git.tag_version" do
    test "v0.2.1" do
      with_mocks([{Ops.Shells.System, [:passthrough], [call: fn _, _ -> "v0.1.0\nv0.2.0\nv0.2.1" end]}]) do
        tag = Ops.Utils.Git.tag_version()
        assert tag == "v0.2.1"
      end
    end
  end

  describe "Utils.Git.parse_tag_version" do
    test "v0.2.1" do
      version = Ops.Utils.Git.parse_tag_version("v0.2.1")
      assert version == "v0.2"
    end

    test "master-v0.2.10" do
      version = Ops.Utils.Git.parse_tag_version("master-v0.2.10")
      assert version == "v0.2"
    end

    test "my_company/repo_name:master-v0.1.0" do
      version = Ops.Utils.Git.parse_tag_version("my_company/repo_name:master-v0.1.0")
      assert version == "v0.1"
    end
  end

  describe "Utils.Git.lookup_date" do
    test "08Jul" do
      with_mocks([{Ops.Shells.System, [:passthrough], [call: fn _, ["log", "-1", "--format=%at"] -> "1562590744" end]}]) do
        date = Ops.Utils.Git.lookup_date()
        assert date == "08Jul"
      end
    end
  end

  describe "Utils.Git.lookup_commit_message_last_row" do
    test "no commands" do
      with_mocks([{Ops.Shells.System, [:passthrough], [call: fn _, _ -> "Test message" end]}]) do
        commands = Ops.Utils.Git.lookup_commit_message_last_row()
        assert commands == "Test message"
      end
    end

    test "only build" do
      with_mocks([{Ops.Shells.System, [:passthrough], [call: fn _, _ -> "Test message\n\nbuild" end]}]) do
        commands = Ops.Utils.Git.lookup_commit_message_last_row()
        assert commands == "build"
      end
    end

    test "deploy to staging" do
      with_mocks([{Ops.Shells.System, [:passthrough], [call: fn _, _ -> "Test message\n\nstaging" end]}]) do
        commands = Ops.Utils.Git.lookup_commit_message_last_row()
        assert commands == "staging"
      end
    end

    test "deploy to staging and deploy to uat fast" do
      with_mocks([{Ops.Shells.System, [:passthrough], [call: fn _, _ -> "Test message\n\nstaging/uat~-f" end]}]) do
        commands = Ops.Utils.Git.lookup_commit_message_last_row()
        assert commands == "staging/uat~-f"
      end
    end
  end

  describe "Utils.Git.datetime_from_seconds" do
    test "~U[2019-07-08 12:59:04Z]" do
      with_mocks([{Ops.Shells.System, [:passthrough], [call: fn _, ["log", "-1", "--format=%at"] -> "1562590744" end]}]) do
        date = Ops.Utils.Git.datetime_from_seconds()
        assert date == ~U[2019-07-08 12:59:04Z]
      end
    end
  end

  describe "Utils.Git.commit_date" do
    test "Mon Jul  8 12:59:04 2019" do
      with_mocks([{Ops.Shells.System, [:passthrough], [call: fn _, ["log", "-1", "--format=%at"] -> "1562590744" end]}]) do
        date = Ops.Utils.Git.commit_date()
        assert date == "Mon Jul  8 12:59:04 2019"
      end
    end
  end

  describe "Utils.Git.commit_message" do
    test "Fake message" do
      with_mocks([
        {Ops.Shells.System, [:passthrough],
         [call: fn _, ["--no-pager", "show", "-s", "--format=%s"] -> "Fake message" end]}
      ]) do
        message = Ops.Utils.Git.commit_message()
        assert message == "Fake message"
      end
    end
  end

  describe "Utils.Git.commit_hash" do
    test "Fake message" do
      with_mocks([
        {Ops.Shells.System, [:passthrough],
         [call: fn _, ["--no-pager", "show", "-s", "--format=%h"] -> "hash-message" end]}
      ]) do
        hash = Ops.Utils.Git.commit_hash()
        assert hash == "hash-message"
      end
    end
  end

  describe "Utils.Git.commit_author" do
    test "Fake message" do
      with_mocks([
        {Ops.Shells.System, [:passthrough],
         [call: fn _, ["--no-pager", "show", "-s", "--format=%an <%ae>"] -> "fake author" end]}
      ]) do
        author = Ops.Utils.Git.commit_author()
        assert author == "fake author"
      end
    end
  end
end
