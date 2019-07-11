defmodule Ops.Sdk.Kub.Client do
  use Sdk.BaseClient, endpoints: Map.keys(Ops.Sdk.Kub.Config.data().endpoints)

  @timeout 20_000

  def prepare_options(options),
    do: %{recv_timeout: @timeout, timeout: @timeout, hackney: [:insecure]} |> Map.merge(options) |> Enum.into([])
end
