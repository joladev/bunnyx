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
end
