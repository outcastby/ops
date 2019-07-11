defmodule Ops.Helpers.Deploy do
  def send_image() do
    case Process.get("image") do
      nil ->
        Process.put("image", "image_1")
        "image_1"

      _ ->
        "image_2"
    end
  end

  def send_containers(containers, new_containers, change \\ false) do
    case Process.get("containers") do
      nil ->
        Process.put("containers", "containers_set")
        containers

      _ ->
        if change, do: new_containers, else: containers ++ new_containers
    end
  end
end
