defmodule Ops.Deploy.SendSlackNotification do
  def messages(env_name, tag) do
    %{
      before:
        ":warning: :warning: :warning: #{env_name} => #{Mix.Project.config()[:app]} => #{tag} => START DEPLOY => #{
          get_initiator()
        } :no_pedestrians:",
      after:
        ":rocket: :rocket: :rocket: #{env_name} => #{Mix.Project.config()[:app]} => #{tag} => DELIVERED => #{
          get_initiator()
        } :muscle_left_anim: :deda: :muscle_right_anim:",
      fail: ":bangbang: :bangbang: :bangbang: #{env_name} => #{Mix.Project.config()[:app]} => #{tag} => DEPLOY FAILED"
    }
  end

  def get_initiator, do: "Initiator #{Ops.Shells.System.call("whoami")}"

  def call(context, type) do
    Ops.Utils.Config.settings()[:slack] |> send(context, type)
    context
  end

  def send([token: _, channel: channel], %{tag: tag, env_name: env_name}, type) do
    payload = %SDK.Request{
      payload: %{
        channel: channel,
        text: messages(env_name, tag)[type]
      }
    }

    Ops.SDK.Slack.Client.send(payload)
  end

  def send(_, _, _), do: nil
end
