defmodule Ops.Utils.Git do
  alias Ops.Shells.System

  @git "git"

  def lookup_image_tag do
    case lookup_branch() do
      "master" -> "master-#{tag_version()}"
      branch_name -> "#{branch_name}-#{System.call(@git, ["rev-parse", "--short=7", "HEAD"])}-#{lookup_date()}"
    end
  end

  def tag_version, do: @git |> System.call(["tag", "-l", "--sort=v:refname"]) |> String.split("\n") |> List.last()

  def parse_tag_version(image) do
    case Regex.run(~r/v\d\.\d/, image) do
      nil -> nil
      [value] -> value
    end
  end

  def datetime_from_seconds(),
    do: @git |> System.call(["log", "-1", "--format=%at"]) |> String.to_integer() |> DateTime.from_unix!()

  def lookup_date, do: datetime_from_seconds() |> Timex.format!("%d%b", :strftime)

  def lookup_branch,
    do:
      @git |> System.call(["symbolic-ref", "--short", "-q", "HEAD"]) |> String.replace("/", "-") |> short_branch_name()

  def short_branch_name("develop"), do: "dev"
  def short_branch_name(branch), do: branch

  def lookup_commit_message_last_row,
    do:
      @git
      |> System.call(["log", "-1", "--pretty=%B"])
      |> String.split("\n\n")
      |> Enum.filter(&(&1 != ""))
      |> List.last()

  def commit_author, do: System.call(@git, ["--no-pager", "show", "-s", "--format=%an <%ae>"])

  def commit_hash, do: System.call(@git, ["--no-pager", "show", "-s", "--format=%h"])

  def commit_message, do: System.call(@git, ["--no-pager", "show", "-s", "--format=%s"])

  def commit_date, do: datetime_from_seconds() |> Timex.format!("{ANSIC}")
end
