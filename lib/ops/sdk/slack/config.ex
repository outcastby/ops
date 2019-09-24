defmodule Ops.SDK.Slack.Config do
  def data,
    do: %{
      base_url: "https://slack.com/api",
      sdk_name: "Slack",
      access_token: get_in(Ops.Utils.Config.settings(), [:slack, :token]),
      endpoints: %{
        send: %{
          type: :post,
          url: "/chat.postMessage?pretty=1"
        }
      }
    }
end
