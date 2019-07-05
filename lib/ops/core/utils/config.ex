defmodule Ops.Utils.Config do
  def settings, do: Application.get_env(Mix.Project.config()[:app], :ops, [])
  def lookup_image_repository(), do: get_in(settings(), [:docker, :image_repository])
  def lookup_available_commands(), do: settings()[:available_environments] ++ ["build"]
  def lookup_built_depends(), do: settings()[:available_environments]
  def lookup_built_branches(), do: settings()[:auto_build_branches]
  def lookup_image_name(tag \\ nil), do: "#{lookup_image_repository()}:#{tag || Ops.Utils.Git.lookup_image_tag()}"
end
