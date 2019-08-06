defmodule Ops.Deploy.Process do
  require IEx
  @check_timeout Ops.Utils.Config.settings()[:check_restart_timeout] || 30

  def call(%{args: args, env_name: env_name} = context) do
    Mix.Tasks.Ops.FetchCert.run([env_name])
    options = Ops.Utils.Kub.options(env_name)

    info = %{
      name: get_name(context, :version),
      options: options,
      image: Ops.Utils.Kub.get_image(options, get_name(context, :prev_version))
    }

    args
    |> exec_playbook()
    |> handle_status(context, info)

    context
  end

  def get_name(context, key) do
    case Map.get(context, key) do
      nil -> "#{Mix.Project.config()[:app]}"
      version -> "#{Mix.Project.config()[:app]}#{String.replace(version, ".", "-")}"
    end
  end

  def exec_playbook(args, exit_on_error \\ false) do
    "ansible-playbook"
    |> System.find_executable()
    |> Ops.Shells.Exec.call(args, [{:line, 4096}], exit_on_error)
  end

  def containers_restarted?(context, %{name: name, options: options} = info) do
    Ops.Utils.Io.puts("Containers not restarted, wait!")
    :timer.sleep(@check_timeout * 1000)

    containers = Ops.Utils.Kub.get_containers(options, name)

    cond do
      Enum.any?(containers, &crash?(&1, name)) -> handle_fail(context, info)
      Enum.all?(containers, &ready?/1) -> Ops.Deploy.SendSlackNotification.call(context, :after)
      true -> containers_restarted?(context, info)
    end
  end

  def handle_fail(context, info), do: context |> Ops.Deploy.SendSlackNotification.call(:fail) |> revert_deploy(info)

  def revert_deploy(%{version: version, prev_version: prev_version, env_name: env_name, tag: tag}, _)
      when prev_version != version,
      do: Mix.Tasks.Ops.Destroy.run([env_name, tag])

  # if this is first deploy and image not exists
  def revert_deploy(%{tag: tag, env_name: env_name}, %{image: nil}),
    do: Mix.Tasks.Ops.Destroy.run([env_name, tag])

  def revert_deploy(%{args: args, tag: tag}, %{image: image}) do
    old_tag = image |> String.split(":") |> List.last()
    args = args |> Enum.map(&String.replace(&1, tag, old_tag))
    exec_playbook(args, true)
  end

  defp handle_status(0, context, %{name: name, options: options, image: image} = info) do
    current_image = Ops.Utils.Kub.get_image(options, name)

    cond do
      image == current_image -> Ops.Deploy.SendSlackNotification.call(context, :after)
      true -> containers_restarted?(context, info)
    end
  end

  defp handle_status(status, context, _) do
    Ops.Deploy.SendSlackNotification.call(context, :fail)
    Ops.Shells.Exec.process_exit(status)
  end

  defp crash?(%{"status" => %{"containerStatuses" => container_statuses}}, name) do
    container_statuses
    |> Enum.find(&(&1["name"] == name))
    |> get_in(["state", "waiting", "reason"])
    |> crash_status?()
  end

  defp crash_status?(status) when status in ["CrashLoopBackOff", "Error"], do: true
  defp crash_status?(_), do: false

  defp ready?(%{"status" => %{"conditions" => conditions}}) do
    conditions
    |> Enum.find(&(&1["type"] == "ContainersReady"))
    |> get_in(["status"])
    |> ready_status?()
  end

  defp ready_status?(status) when status == "True", do: true
  defp ready_status?(_), do: false
end
