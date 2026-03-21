defmodule Bunnyx.MagicContainersTest do
  use ExUnit.Case, async: true
  use Mimic

  setup do
    %{client: Bunnyx.new(api_key: "sk-test")}
  end

  describe "list/2" do
    test "returns parsed applications", %{client: client} do
      response = %{"data" => [Bunnyx.Factory.mc_app_response()], "nextCursor" => nil}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/mc/apps", opts ->
        assert opts[:params] == %{}
        {:ok, response}
      end)

      assert {:ok, result} = Bunnyx.MagicContainers.list(client)
      assert [%Bunnyx.MagicContainers.App{id: "app-abc-123", name: "my-app"}] = result["data"]
    end
  end

  describe "get/2" do
    test "returns parsed application", %{client: client} do
      response = Bunnyx.Factory.mc_app_response()

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/mc/apps/app-1", _opts ->
        {:ok, response}
      end)

      assert {:ok, %Bunnyx.MagicContainers.App{id: "app-abc-123", name: "my-app"}} =
               Bunnyx.MagicContainers.get(client, "app-1")
    end
  end

  describe "create/2" do
    test "sends keyword attrs and returns parsed app", %{client: client} do
      response = Bunnyx.Factory.mc_app_response()

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/mc/apps", opts ->
        assert opts[:json]["name"] == "my-app"
        assert opts[:json]["runtimeType"] == "Shared"
        {:ok, response}
      end)

      assert {:ok, %Bunnyx.MagicContainers.App{name: "my-app"}} =
               Bunnyx.MagicContainers.create(client, name: "my-app", runtime_type: "Shared")
    end
  end

  describe "update/3" do
    test "sends keyword attrs", %{client: client} do
      response = Bunnyx.Factory.mc_app_response(%{"name" => "updated"})

      expect(Bunnyx.HTTP, :request, fn _req, :put, "/mc/apps/app-1", opts ->
        assert opts[:json]["name"] == "updated"
        {:ok, response}
      end)

      assert {:ok, %Bunnyx.MagicContainers.App{}} =
               Bunnyx.MagicContainers.update(client, "app-1", name: "updated")
    end
  end

  describe "patch/3" do
    test "partially updates", %{client: client} do
      response = %{"id" => "app-1"}

      expect(Bunnyx.HTTP, :request, fn _req, :patch, "/mc/apps/app-1", opts ->
        assert opts[:json]["name"] == "patched"
        {:ok, response}
      end)

      assert {:ok, _} = Bunnyx.MagicContainers.patch(client, "app-1", %{"name" => "patched"})
    end
  end

  describe "delete/2" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :delete, "/mc/apps/app-1", _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.MagicContainers.delete(client, "app-1")
    end
  end

  describe "deploy/2" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :post, "/mc/apps/app-1/deploy", _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.MagicContainers.deploy(client, "app-1")
    end
  end

  describe "undeploy/2" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :post, "/mc/apps/app-1/undeploy", _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.MagicContainers.undeploy(client, "app-1")
    end
  end

  describe "restart/2" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :post, "/mc/apps/app-1/restart", _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.MagicContainers.restart(client, "app-1")
    end
  end

  describe "overview/2" do
    test "returns overview", %{client: client} do
      response = %{"status" => "running"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/mc/apps/app-1/overview", _opts ->
        {:ok, response}
      end)

      assert {:ok, %{"status" => "running"}} = Bunnyx.MagicContainers.overview(client, "app-1")
    end
  end

  describe "statistics/2" do
    test "returns statistics", %{client: client} do
      response = %{"cpuUsage" => 0.5}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/mc/apps/app-1/statistics", _opts ->
        {:ok, response}
      end)

      assert {:ok, %{"cpuUsage" => 0.5}} = Bunnyx.MagicContainers.statistics(client, "app-1")
    end
  end

  # -- Container Registries --

  describe "list_registries/1" do
    test "returns registries", %{client: client} do
      response = [%{"id" => 1, "displayName" => "Docker Hub"}]

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/mc/registries", _opts ->
        {:ok, response}
      end)

      assert {:ok, [%{"id" => 1}]} = Bunnyx.MagicContainers.list_registries(client)
    end
  end

  describe "get_registry/2" do
    test "returns a registry", %{client: client} do
      response = %{"id" => 1, "displayName" => "Docker Hub"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/mc/registries/1", _opts ->
        {:ok, response}
      end)

      assert {:ok, %{"id" => 1}} = Bunnyx.MagicContainers.get_registry(client, 1)
    end
  end

  describe "add_registry/2" do
    test "sends config", %{client: client} do
      config = %{"displayName" => "My Registry", "type" => "DockerHub"}
      response = %{"id" => 1}

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/mc/registries", opts ->
        assert opts[:json] == config
        {:ok, response}
      end)

      assert {:ok, %{"id" => 1}} = Bunnyx.MagicContainers.add_registry(client, config)
    end
  end

  describe "update_registry/3" do
    test "sends updated config", %{client: client} do
      response = %{"id" => 1}

      expect(Bunnyx.HTTP, :request, fn _req, :put, "/mc/registries/1", _opts ->
        {:ok, response}
      end)

      assert {:ok, _} =
               Bunnyx.MagicContainers.update_registry(client, 1, %{"displayName" => "Updated"})
    end
  end

  describe "delete_registry/2" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :delete, "/mc/registries/1", _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.MagicContainers.delete_registry(client, 1)
    end
  end

  describe "list_images/2" do
    test "returns images", %{client: client} do
      response = %{"images" => []}

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/mc/registries/images", _opts ->
        {:ok, response}
      end)

      assert {:ok, _} = Bunnyx.MagicContainers.list_images(client, %{"registryId" => 1})
    end
  end

  describe "search_public_images/2" do
    test "returns search results", %{client: client} do
      response = %{"images" => [%{"name" => "nginx"}]}

      expect(Bunnyx.HTTP, :request, fn _req,
                                       :post,
                                       "/mc/registries/public-images/search",
                                       _opts ->
        {:ok, response}
      end)

      assert {:ok, _} =
               Bunnyx.MagicContainers.search_public_images(client, %{"prefix" => "nginx"})
    end
  end

  # -- Container Templates --

  describe "add_container/3" do
    test "sends container config", %{client: client} do
      config = %{"image" => "nginx:latest"}
      response = %{"id" => "c-1"}

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/mc/apps/app-1/containers", opts ->
        assert opts[:json] == config
        {:ok, response}
      end)

      assert {:ok, %{"id" => "c-1"}} =
               Bunnyx.MagicContainers.add_container(client, "app-1", config)
    end
  end

  describe "get_container/3" do
    test "returns container", %{client: client} do
      response = %{"id" => "c-1", "image" => "nginx:latest"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/mc/apps/app-1/containers/c-1", _opts ->
        {:ok, response}
      end)

      assert {:ok, %{"id" => "c-1"}} =
               Bunnyx.MagicContainers.get_container(client, "app-1", "c-1")
    end
  end

  describe "delete_container/3" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :delete, "/mc/apps/app-1/containers/c-1", _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.MagicContainers.delete_container(client, "app-1", "c-1")
    end
  end

  describe "set_container_env/4" do
    test "sends env vars", %{client: client} do
      env = [%{"name" => "PORT", "value" => "8080"}]

      expect(Bunnyx.HTTP, :request, fn _req, :put, "/mc/apps/app-1/containers/c-1/env", opts ->
        assert opts[:json] == env
        {:ok, ""}
      end)

      assert {:ok, nil} =
               Bunnyx.MagicContainers.set_container_env(client, "app-1", "c-1", env)
    end
  end

  # -- Endpoints --

  describe "list_endpoints/2" do
    test "returns endpoints", %{client: client} do
      response = [%{"id" => "ep-1", "type" => "CDN"}]

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/mc/apps/app-1/endpoints", _opts ->
        {:ok, response}
      end)

      assert {:ok, [%{"id" => "ep-1"}]} = Bunnyx.MagicContainers.list_endpoints(client, "app-1")
    end
  end

  describe "add_endpoint/4" do
    test "sends config", %{client: client} do
      config = %{"type" => "CDN"}
      response = %{"id" => "ep-1"}

      expect(Bunnyx.HTTP, :request, fn _req,
                                       :post,
                                       "/mc/apps/app-1/containers/c-1/endpoints",
                                       opts ->
        assert opts[:json] == config
        {:ok, response}
      end)

      assert {:ok, _} = Bunnyx.MagicContainers.add_endpoint(client, "app-1", "c-1", config)
    end
  end

  describe "delete_endpoint/3" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :delete, "/mc/apps/app-1/endpoints/ep-1", _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.MagicContainers.delete_endpoint(client, "app-1", "ep-1")
    end
  end

  # -- Autoscaling --

  describe "get_autoscaling/2" do
    test "returns autoscaling config", %{client: client} do
      response = %{"minReplicas" => 1, "maxReplicas" => 5}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/mc/apps/app-1/autoscaling", _opts ->
        {:ok, response}
      end)

      assert {:ok, %{"minReplicas" => 1}} =
               Bunnyx.MagicContainers.get_autoscaling(client, "app-1")
    end
  end

  describe "update_autoscaling/3" do
    test "sends config", %{client: client} do
      response = %{"minReplicas" => 2}

      expect(Bunnyx.HTTP, :request, fn _req, :put, "/mc/apps/app-1/autoscaling", opts ->
        assert opts[:json]["minReplicas"] == 2
        {:ok, response}
      end)

      assert {:ok, _} =
               Bunnyx.MagicContainers.update_autoscaling(client, "app-1", %{"minReplicas" => 2})
    end
  end

  # -- Regions --

  describe "list_regions/1" do
    test "returns regions", %{client: client} do
      response = [%{"code" => "DE", "name" => "Frankfurt"}]

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/mc/regions", _opts ->
        {:ok, response}
      end)

      assert {:ok, [%{"code" => "DE"}]} = Bunnyx.MagicContainers.list_regions(client)
    end
  end

  describe "get_optimal_region/2" do
    test "returns optimal region", %{client: client} do
      response = %{"regionCode" => "DE"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/mc/regions/optimal", opts ->
        assert opts[:params]["cdnServerToken"] == "tok-123"
        {:ok, response}
      end)

      assert {:ok, _} = Bunnyx.MagicContainers.get_optimal_region(client, "tok-123")
    end
  end

  # -- Volumes --

  describe "list_volumes/2" do
    test "returns volumes", %{client: client} do
      response = [%{"id" => "vol-1"}]

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/mc/apps/app-1/volumes", _opts ->
        {:ok, response}
      end)

      assert {:ok, [%{"id" => "vol-1"}]} = Bunnyx.MagicContainers.list_volumes(client, "app-1")
    end
  end

  describe "detach_volume/3" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req,
                                       :post,
                                       "/mc/apps/app-1/volumes/vol-1/detach",
                                       _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.MagicContainers.detach_volume(client, "app-1", "vol-1")
    end
  end

  # -- Nodes --

  describe "list_nodes/2" do
    test "returns nodes", %{client: client} do
      response = %{"data" => [%{"ip" => "1.2.3.4"}]}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/mc/nodes", _opts ->
        {:ok, response}
      end)

      assert {:ok, _} = Bunnyx.MagicContainers.list_nodes(client)
    end
  end

  # -- Pods --

  describe "recreate_pod/3" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :post, "/mc/apps/app-1/pods/pod-1/recreate", _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.MagicContainers.recreate_pod(client, "app-1", "pod-1")
    end
  end

  # -- Limits --

  describe "get_limits/1" do
    test "returns user limits", %{client: client} do
      response = %{"maxApps" => 10, "currentApps" => 3}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/mc/limits", _opts ->
        {:ok, response}
      end)

      assert {:ok, %{"maxApps" => 10}} = Bunnyx.MagicContainers.get_limits(client)
    end
  end

  # -- Log Forwarding --

  describe "list_log_forwarding/1" do
    test "returns configs", %{client: client} do
      response = [%{"id" => "lf-1"}]

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/mc/log/forwarding", _opts ->
        {:ok, response}
      end)

      assert {:ok, [%{"id" => "lf-1"}]} = Bunnyx.MagicContainers.list_log_forwarding(client)
    end
  end

  describe "create_log_forwarding/2" do
    test "sends config", %{client: client} do
      config = %{"type" => "http", "url" => "https://logs.example.com"}
      response = %{"id" => "lf-1"}

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/mc/log/forwarding", opts ->
        assert opts[:json] == config
        {:ok, response}
      end)

      assert {:ok, _} = Bunnyx.MagicContainers.create_log_forwarding(client, config)
    end
  end

  describe "delete_log_forwarding/2" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :delete, "/mc/log/forwarding/lf-1", _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.MagicContainers.delete_log_forwarding(client, "lf-1")
    end
  end
end
