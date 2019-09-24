defmodule Ops.SDK.DockerHub.Client do
  use SDK.BaseClient, endpoints: Map.keys(Ops.SDK.DockerHub.Config.data().endpoints)
end
