defmodule Ops.Sdk.Slack.Client do
  use Sdk.BaseClient, endpoints: Map.keys(Ops.Sdk.Slack.Config.data().endpoints)

  def prepare_headers(headers) do
    token = Ops.Sdk.Slack.Config.data().access_token
    unless token, do: raise("Parameter 'slack_token', must be set")
    [Authorization: "Bearer " <> token, "Content-Type": "application/json"] ++ headers
  end
end
