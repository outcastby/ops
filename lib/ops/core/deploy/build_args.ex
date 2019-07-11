defmodule Ops.Deploy.BuildArgs do
  def call(context, is_fast) do
    %{version: version, prev_version: prev_version, tag: tag, prev_tag: prev_tag, env_name: env_name} = context

    args =
      [
        "-i",
        "inventory",
        "playbook.yml",
        "--extra-vars",
        "env_name=#{env_name} image_tag=#{tag} version=#{version} prev_image_tag=#{prev_tag} prev_version=#{
          prev_version
        }"
      ]
      |> skip_tags(context, is_fast)

    %{context | args: args}
  end

  def skip_tags(args, context, is_fast),
    do: args ++ ["--skip-tags", ["fetch"] |> skip_release_tag(context) |> skip_job_tag(is_fast) |> Enum.join(",")]

  def skip_release_tag(tags, %{version: version, prev_version: prev_version, env_name: env_name})
      when version == prev_version or env_name != "prod",
      do: tags ++ ["release"]

  def skip_release_tag(tags, _), do: tags
  def skip_job_tag(tags, true), do: tags ++ ["job"]
  def skip_job_tag(tags, _), do: tags
end
