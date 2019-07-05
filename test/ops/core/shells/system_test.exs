defmodule Ops.Shells.SystemTest do
  use ExUnit.Case
  import Mock

  describe ".call" do
    test "bad command" do
      with_mocks([{System, [:passthrough], [cmd: fn _, _ -> {"Bad", 100} end]}]) do
        value = Ops.Shells.System.call("", [])
        assert value == nil
      end
    end

    test "good command with trim \n" do
      with_mocks([{System, [:passthrough], [cmd: fn _, _ -> {"Good\n", 0} end]}]) do
        value = Ops.Shells.System.call("", [])
        assert value == "Good"
      end
    end

    test "good command with trim white space" do
      with_mocks([{System, [:passthrough], [cmd: fn _, _ -> {"Good ", 0} end]}]) do
        value = Ops.Shells.System.call("", [])
        assert value == "Good"
      end
    end
  end
end
