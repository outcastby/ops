defmodule Ops.Deploy.Process.CommonTest do
  use ExUnit.Case
  import Mock

  setup_with_mocks([
    {Ops.Utils.Io, [], [puts: fn _ -> "" end]},
    {Mix.Tasks.Ops.FetchCert, [], [run: fn _ -> "" end]},
    {Ops.Deploy.SendSlackNotification, [], [call: fn context, _ -> context end]}
  ]) do
    containers = [
      %{
        "metadata" => %{"labels" => %{"app" => "ops", "pod-template-hash" => "ccccc"}, "uid" => "1"},
        "spec" => %{
          "containers" => [
            %{"image" => "my_repo:develop", "name" => "ops"},
            %{"image" => "image", "name" => "kube-proxy"}
          ]
        },
        "status" => %{
          "containerStatuses" => [
            %{
              "name" => "ops",
              "state" => %{"running" => %{"startedAt" => "2019-07-11T13:32:30Z"}}
            },
            %{
              "name" => "kube-proxy",
              "state" => %{"running" => %{"startedAt" => "2019-07-11T13:32:31Z"}}
            }
          ]
        }
      }
    ]

    bad_containers = [
      %{
        "metadata" => %{"labels" => %{"app" => "ops", "pod-template-hash" => "ddddd"}, "uid" => "2"},
        "status" => %{
          "containerStatuses" => [
            %{
              "name" => "ops",
              "state" => %{
                "waiting" => %{
                  "message" => "fake",
                  "reason" => "CrashLoopBackOff"
                }
              }
            },
            %{
              "name" => "kube-proxy",
              "state" => %{"running" => %{"startedAt" => "2019-07-11T13:32:31Z"}}
            }
          ]
        }
      }
    ]

    new_containers = [
      %{
        "metadata" => %{"labels" => %{"app" => "ops", "pod-template-hash" => "ddddd"}, "uid" => "3"},
        "status" => %{
          "conditions" => [
            %{
              "lastProbeTime" => nil,
              "lastTransitionTime" => "2019-07-25T12:02:20Z",
              "message" => "containers with unready status: [kube-proxy]",
              "reason" => "ContainersNotReady",
              "status" => "True",
              "type" => "ContainersReady"
            },
          ],
          "containerStatuses" => [
            %{
              "name" => "ops",
              "state" => %{"running" => %{"startedAt" => "2019-07-11T13:32:31Z"}}
            },
            %{
              "name" => "kube-proxy",
              "state" => %{"running" => %{"startedAt" => "2019-07-11T13:32:31Z"}}
            }
          ]
        }
      }
    ]

    context = %Ops.Deploy.Context{
      args: [
        "-i",
        "inventory",
        "playbook.yml",
        "--extra-vars",
        "env_name=uat image_tag=feature-fake version= prev_image_tag= prev_version=",
        "--skip-tags",
        "fetch,release"
      ],
      env_name: "uat",
      prev_tag: nil,
      prev_version: nil,
      tag: "feature-fake",
      version: nil
    }

    %{containers: containers, new_containers: new_containers, bad_containers: bad_containers, context: context}
  end

  describe ".call" do
    test "check fail deploy" do
      with_mocks([
        {Ops.Shells.Exec, [], [call: fn _, _, _, _ -> 100 end, process_exit: fn _ -> "" end]},
        {Ops.Utils.Kub, [:passthrough],
          [options: fn _ -> "" end, get_image: fn _, _ -> "image" end, get_containers: fn _, _ -> [] end]}
      ]) do
        Ops.Deploy.Process.call(%{args: [], env_name: "uat", version: nil})
        assert called(Ops.Deploy.SendSlackNotification.call(:_, :fail))
      end
    end

    test "check ok, image not changes" do
      with_mocks([
        {Ops.Shells.Exec, [], [call: fn _, _, _, _ -> 0 end]},
        {Ops.Utils.Kub, [:passthrough],
          [options: fn _ -> "" end, get_image: fn _, _ -> "image" end, get_containers: fn _, _ -> [] end]}
      ]) do
        Ops.Deploy.Process.call(%{args: [], env_name: "uat", version: nil})
        assert called(Ops.Deploy.SendSlackNotification.call(:_, :after))
      end
    end

    test "check fail, container crash", %{containers: containers, bad_containers: bad_containers, context: context} do
      with_mocks([
        {Ops.Shells.Exec, [], [call: fn _, _, _, _ -> 0 end]},
        {Ops.Utils.Kub, [:passthrough],
          [
            options: fn _ -> "" end,
            get_image: fn _, _ -> Ops.Helpers.Deploy.send_image() end,
            get_containers: fn _, _ -> Ops.Helpers.Deploy.send_containers(containers, bad_containers) end
          ]}
      ]) do
        Ops.Deploy.Process.call(context)
        assert called(Ops.Deploy.SendSlackNotification.call(:_, :fail))
      end
    end

    test "check ok, container crash", %{containers: containers, new_containers: new_containers, context: context} do
      with_mocks([
        {Ops.Shells.Exec, [], [call: fn _, _, _, _ -> 0 end]},
        {Ops.Utils.Kub, [:passthrough],
          [
            options: fn _ -> "" end,
            get_image: fn _, _ -> Ops.Helpers.Deploy.send_image() end,
            get_containers: fn _, _ -> Ops.Helpers.Deploy.send_containers(containers, new_containers, true) end
          ]}
      ]) do
        Ops.Deploy.Process.call(context)
        assert called(Ops.Deploy.SendSlackNotification.call(:_, :after))
      end
    end
  end

  describe ".containers_restarted?" do
    test "check fail by status", %{containers: containers, bad_containers: bad_containers, context: context} do
      with_mocks([
        {Ops.Shells.Exec, [], [call: fn _, _, _, _ -> 0 end]},
        {Ops.Shells.Exec, [], [call: fn _, _, _ -> 0 end]},
        {Ops.Utils.Kub, [:passthrough], [get_containers: fn _, _ -> containers ++ bad_containers end]}
      ]) do
        info = %{old_containers: containers, options: "", name: "ops"}
        Ops.Deploy.Process.containers_restarted?(context, info)
        assert called(Ops.Deploy.SendSlackNotification.call(:_, :fail))
      end
    end

    test "check containers is restarted", %{containers: containers, new_containers: new_containers} do
      with_mocks([
        {Ops.Utils.Kub, [:passthrough], [get_containers: fn _, _ -> new_containers end]}
      ]) do
        info = %{old_containers: containers, options: "", name: "ops"}
        Ops.Deploy.Process.containers_restarted?(%{env_name: "uat"}, info)

        assert called(Ops.Deploy.SendSlackNotification.call(:_, :after))
      end
    end
  end
end
