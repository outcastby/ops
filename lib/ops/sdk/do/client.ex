defmodule Ops.Sdk.Do.Client do
  use Sdk.BaseClient, endpoints: Map.keys(Ops.Sdk.Do.Config.data().endpoints)

  def prepare_headers(headers) do
    token = Ops.Sdk.Do.Config.data().access_token
    unless token, do: raise("Parameter 'do_access_token', must be set")
    [Authorization: "Bearer " <> token] ++ headers
  end
end
