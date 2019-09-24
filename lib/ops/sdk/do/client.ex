defmodule Ops.SDK.Do.Client do
  use SDK.BaseClient, endpoints: Map.keys(Ops.SDK.Do.Config.data().endpoints)

  def prepare_headers(headers) do
    token = Ops.SDK.Do.Config.data().access_token
    unless token, do: raise("Parameter '[:do_configuration][:access_token]', must be set")
    [Authorization: "Bearer " <> token] ++ headers
  end
end
