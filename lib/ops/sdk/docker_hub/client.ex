defmodule Ops.Sdk.DockerHub.Client do
  use Sdk.BaseClient, endpoints: Map.keys(Ops.Sdk.DockerHub.Config.data().endpoints)
end
