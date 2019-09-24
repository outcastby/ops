defmodule Ops.SDK.Slack.Client do
  use SDK.BaseClient, endpoints: Map.keys(Ops.SDK.Slack.Config.data().endpoints)

  def prepare_headers(headers) do
    token = Ops.SDK.Slack.Config.data().access_token
    unless token, do: raise("Parameter 'slack_token', must be set")
    [Authorization: "Bearer " <> token, "Content-Type": "application/json"] ++ headers
  end
end
