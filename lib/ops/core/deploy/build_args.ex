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
      |> skip_release_tag(context)
      |> skip_job_tag(is_fast)

    %{context | args: args}
  end

  def skip_release_tag(args, %{version: version, prev_version: prev_version, env_name: env_name})
      when version == prev_version or env_name != "prod" do
    Ops.Utils.Io.puts("Tag release is skipped")
    args ++ ["--skip-tags", "release"]
  end

  def skip_release_tag(args, _), do: args

  def skip_job_tag(args, true) do
    Ops.Utils.Io.puts("Job is skipped")

    case Enum.find_index(args, &(&1 == "--skip-tags")) do
      nil -> args ++ ["--skip-tags", "job"]
      index -> List.replace_at(args, index + 1, "#{Enum.at(args, index + 1)},job")
    end
  end

  def skip_job_tag(args, _), do: args
end
