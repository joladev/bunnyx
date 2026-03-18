defmodule Bunnyx.MagicContainersTest do
  use ExUnit.Case, async: true
  use Mimic

  setup do
    %{client: Bunnyx.new(api_key: "sk-test")}
  end

  describe "list/2" do
    test "returns applications", %{client: client} do
      response = %{"data" => [%{"id" => "app-1"}], "nextCursor" => nil}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/mc/apps", opts ->
        assert opts[:params] == %{}
        {:ok, response}
      end)

      assert {:ok, %{"data" => [%{"id" => "app-1"}]}} = Bunnyx.MagicContainers.list(client)
    end
  end

  describe "get/2" do
    test "returns application", %{client: client} do
      response = %{"id" => "app-1", "name" => "my-app"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/mc/apps/app-1", _opts ->
        {:ok, response}
      end)

      assert {:ok, %{"id" => "app-1"}} = Bunnyx.MagicContainers.get(client, "app-1")
    end
  end

  describe "create/2" do
    test "sends config and returns app", %{client: client} do
      config = %{"name" => "my-app", "runtimeType" => "Shared"}
      response = %{"id" => "app-1"}

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/mc/apps", opts ->
        assert opts[:json] == config
        {:ok, response}
      end)

      assert {:ok, %{"id" => "app-1"}} = Bunnyx.MagicContainers.create(client, config)
    end
  end

  describe "update/3" do
    test "replaces full config", %{client: client} do
      response = %{"id" => "app-1"}

      expect(Bunnyx.HTTP, :request, fn _req, :put, "/mc/apps/app-1", opts ->
        assert opts[:json]["name"] == "updated"
        {:ok, response}
      end)

      assert {:ok, _} = Bunnyx.MagicContainers.update(client, "app-1", %{"name" => "updated"})
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
end
