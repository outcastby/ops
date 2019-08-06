defmodule Ops.Helpers.Deploy do
  def send_image(initial_image \\ "image_1") do
    case Process.get("image") do
      nil ->
        Process.put("image", "image_exist")
        initial_image

      _ ->
        "image_2"
    end
  end
end
