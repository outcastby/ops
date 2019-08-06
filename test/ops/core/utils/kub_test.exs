defmodule Ops.Utils.KubTest do
  use ExUnit.Case
  import Mock
  require IEx

  test ".options" do
    with_mocks([
      {Ops.Shells.System, [],
       [
         call: fn
           _,
           [
             "--kubeconfig=tmp/uat-kubeconfig.yml",
             "config",
             "view",
             "--minify",
             "-o",
             "jsonpath={.clusters[0].cluster.server}"
           ] ->
             "api_url"

           _, _ ->
             Base.encode64("token")
         end
       ]}
    ]) do
      options = Ops.Utils.Kub.options("uat")
      assert options == %{url_params: %{base_url: "api_url", token: "token"}}
    end
  end

  test ".config_file" do
    file = Ops.Utils.Kub.config_file("uat")
    assert file == "--kubeconfig=tmp/uat-kubeconfig.yml"
  end

  test ".get_url" do
    with_mocks([{Ops.Shells.System, [], [call: fn _, _ -> "url" end]}]) do
      url = Ops.Utils.Kub.get_url("uat")
      assert url == "url"
    end
  end

  test ".get_token" do
    with_mocks([{Ops.Shells.System, [], [call: fn _, _ -> Base.encode64("token") end]}]) do
      token = Ops.Utils.Kub.get_token("uat")
      assert token == "token"
    end
  end

  test ".base_request" do
    request = Ops.Utils.Kub.base_request(%{url_params: %{base_url: "url", token: "token"}})

    assert request == %Sdk.Request{
             headers: [{"Authorization", "Bearer token"}],
             options: %{url_params: %{base_url: "url", token: "token"}}
           }
  end

  test ".get_containers" do
    with_mocks([
      {Ops.Sdk.Kub.Client, [],
       [
         pods: fn _ ->
           {:ok,
            %{
              "items" => [
                %{
                  "metadata" => %{"labels" => %{"app" => "ops", "pod-template-hash" => "ddddd"}},
                  "spec" => %{},
                  "statuses" => %{}
                },
                %{
                  "metadata" => %{"labels" => %{"app" => "fake", "pod-template-hash" => "ddddd"}},
                  "spec" => %{},
                  "statuses" => %{}
                }
              ]
            }}
         end
       ]}
    ]) do
      containers = Ops.Utils.Kub.get_containers(%{url_params: %{base_url: "url", token: "token"}}, "ops")

      assert containers == [
               %{
                 "metadata" => %{"labels" => %{"app" => "ops", "pod-template-hash" => "ddddd"}},
                 "spec" => %{},
                 "statuses" => %{}
               }
             ]
    end
  end

  describe ".get_image" do
    test "if deployment exists" do
      with_mocks([
        {Ops.Sdk.Kub.Client, [],
         [
           deployment: fn _ ->
             {:ok,
              %{
                "spec" => %{
                  "template" => %{
                    "spec" => %{
                      "containers" => [
                        %{
                          "image" => "ops_image",
                          "name" => "ops"
                        },
                        %{
                          "image" => "kube_image",
                          "name" => "kube"
                        }
                      ]
                    }
                  }
                }
              }}
           end
         ]}
      ]) do
        image = Ops.Utils.Kub.get_image(%{url_params: %{base_url: "url", token: "token"}}, "ops")
        assert image == "ops_image"
      end
    end

    test "if deployment not found" do
      with_mocks([
        {Ops.Sdk.Kub.Client, [],
         [
           deployment: fn _ ->
             {:error,
              %{
                "apiVersion" => "v1",
                "code" => 404,
                "details" => %{
                  "group" => "apps",
                  "kind" => "deployments",
                  "name" => "ops-fake"
                },
                "kind" => "Status",
                "message" => "deployments.apps \"ops-fake\" not found",
                "metadata" => %{},
                "reason" => "NotFound",
                "status" => "Failure"
              }}
           end
         ]}
      ]) do
        image = Ops.Utils.Kub.get_image(%{url_params: %{base_url: "url", token: "token"}}, "ops")
        assert is_nil(image)
      end
    end
  end
end
