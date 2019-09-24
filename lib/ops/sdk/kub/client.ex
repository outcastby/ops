defmodule Ops.SDK.Kub.Client do
  use SDK.BaseClient, endpoints: Map.keys(Ops.SDK.Kub.Config.data().endpoints)

  @timeout 20_000

  def prepare_options(options),
    do: %{recv_timeout: @timeout, timeout: @timeout, hackney: [:insecure]} |> Map.merge(options) |> Enum.into([])
end
