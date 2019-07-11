defmodule Ops.Deploy.Process.WithVersionsTest do
  use ExUnit.Case
  import Mock

  setup_with_mocks([
    {Ops.Utils.Io, [], [puts: fn _ -> "" end]},
    {Mix.Tasks.Ops.FetchCert, [], [run: fn _ -> "" end]},
    {Ops.Deploy.SendSlackNotification, [], [call: fn context, _ -> context end]}
  ]) do
    containers = [
      %{
        "metadata" => %{"labels" => %{"app" => "opsv0-1", "pod-template-hash" => "ccccc"}, "uid" => "1"},
        "spec" => %{
          "containers" => [
            %{"image" => "my_repo:master-v0.1.0", "name" => "opsv0-1"},
            %{"image" => "image", "name" => "kube-proxy"}
          ]
        },
        "status" => %{
          "containerStatuses" => [
            %{
              "name" => "opsv0-1",
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
        "metadata" => %{"labels" => %{"app" => "opsv0-2", "pod-template-hash" => "ddddd"}, "uid" => "2"},
        "status" => %{
          "containerStatuses" => [
            %{
              "name" => "opsv0-2",
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

    hotfix_bad_containers = [
      %{
        "metadata" => %{"labels" => %{"app" => "opsv0-1", "pod-template-hash" => "ddddd"}, "uid" => "2"},
        "status" => %{
          "containerStatuses" => [
            %{
              "name" => "opsv0-1",
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
        "metadata" => %{"labels" => %{"app" => "opsv0-2", "pod-template-hash" => "ddddd"}, "uid" => "3"},
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
              "name" => "opsv0-2",
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
      env_name: "prod",
      prev_tag: "master-v0.1.0",
      prev_version: "v0.1",
      tag: "master-v0.2.0",
      version: "v0.2",
      args: [
        "-i",
        "inventory",
        "playbook.yml",
        "--extra-vars",
        "env_name=prod image_tag=master-v0.2.0 version=v0.2 prev_image_tag=master-v0.1.0 prev_version=v0.1",
        "--skip-tags",
        "fetch"
      ]
    }

    hotfix_context = %Ops.Deploy.Context{
      env_name: "prod",
      prev_tag: "master-v0.1.0",
      prev_version: "v0.1",
      tag: "master-v0.1.1",
      version: "v0.1",
      args: [
        "-i",
        "inventory",
        "playbook.yml",
        "--extra-vars",
        "env_name=prod image_tag=master-v0.1.1 version=v0.1 prev_image_tag=master-v0.1.0 prev_version=v0.1",
        "--skip-tags",
        "fetch"
      ]
    }

    %{
      containers: containers,
      new_containers: new_containers,
      bad_containers: bad_containers,
      context: context,
      hotfix_context: hotfix_context,
      hotfix_bad_containers: hotfix_bad_containers
    }
  end

  describe ".call" do
    test "check fail, release containers crash", %{
      containers: containers,
      bad_containers: bad_containers,
      context: context
    } do
      with_mocks([
        {Ops.Shells.Exec, [], [call: fn _, _, _, _ -> 0 end]},
        {Ops.Shells.Exec, [], [call: fn _, _, _ -> 0 end]},
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

    test "check fail, hotfix containers crash", %{
      containers: containers,
      hotfix_bad_containers: bad_containers,
      hotfix_context: context
    } do
      with_mocks([
        {Ops.Shells.Exec, [], [call: fn _, _, _, _ -> 0 end]},
        {Ops.Shells.Exec, [], [call: fn _, _, _ -> 0 end]},
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
end
