defmodule Ops.Deploy.SendSlackNotificationTest do
  use ExUnit.Case
  import Mock

  test ".call" do
    with_mock(Ops.Sdk.Slack.Client, send: fn _ -> "" end) do
      result =
        Ops.Deploy.SendSlackNotification.call(
          %Ops.Deploy.Context{
            version: nil,
            prev_version: nil,
            tag: "develop-test",
            prev_tag: nil,
            env_name: "uat"
          },
          :before
        )

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
