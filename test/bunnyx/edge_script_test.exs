defmodule Bunnyx.EdgeScriptTest do
  use ExUnit.Case, async: true
  use Mimic

  setup do
    %{client: Bunnyx.new(api_key: "sk-test")}
  end

  describe "list/2" do
    test "returns parsed scripts", %{client: client} do
      response = %{
        "Items" => [%{"Id" => 1, "Name" => "my-script"}],
        "CurrentPage" => 1,
        "TotalItems" => 1,
        "HasMoreItems" => false
      }

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/compute/script", opts ->
        assert opts[:params] == %{}
        {:ok, response}
      end)

      assert {:ok, page} = Bunnyx.EdgeScript.list(client)
      assert [%{"Id" => 1}] = page.items
      assert page.total_items == 1
    end
  end

  describe "get/2" do
    test "returns script", %{client: client} do
      response = %{"Id" => 1, "Name" => "my-script", "ScriptType" => 1}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/compute/script/1", _opts ->
        {:ok, response}
      end)

      assert {:ok, %{"Id" => 1}} = Bunnyx.EdgeScript.get(client, 1)
    end
  end

  describe "create/2" do
    test "sends attrs and returns script", %{client: client} do
      response = %{"Id" => 1, "Name" => "new-script"}

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/compute/script", opts ->
        assert opts[:json] == %{"Name" => "new-script", "ScriptType" => 1}
        {:ok, response}
      end)

      assert {:ok, %{"Id" => 1}} =
               Bunnyx.EdgeScript.create(client, name: "new-script", script_type: 1)
    end
  end

  describe "update/3" do
    test "sends attrs to correct path", %{client: client} do
      response = %{"Id" => 1, "Name" => "updated"}

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/compute/script/1", opts ->
        assert opts[:json] == %{"Name" => "updated"}
        {:ok, response}
      end)

      assert {:ok, _} = Bunnyx.EdgeScript.update(client, 1, name: "updated")
    end
  end

  describe "delete/2" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :delete, "/compute/script/1", _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.EdgeScript.delete(client, 1)
    end
  end

  describe "statistics/2" do
    test "returns script statistics", %{client: client} do
      response = %{"TotalRequests" => 1000}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/compute/script/1/statistics", _opts ->
        {:ok, response}
      end)

      assert {:ok, %{"TotalRequests" => 1000}} = Bunnyx.EdgeScript.statistics(client, 1)
    end
  end

  describe "rotate_deployment_key/2" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req,
                                       :post,
                                       "/compute/script/1/deploymentKey/rotate",
                                       _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.EdgeScript.rotate_deployment_key(client, 1)
    end
  end

  describe "get_code/2" do
    test "returns code and metadata", %{client: client} do
      response = %{"Code" => "export default {}", "LastModified" => "2025-06-01T00:00:00Z"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/compute/script/1/code", _opts ->
        {:ok, response}
      end)

      assert {:ok, %{"Code" => "export default {}"}} = Bunnyx.EdgeScript.get_code(client, 1)
    end
  end

  describe "set_code/3" do
    test "sends code and returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :post, "/compute/script/1/code", opts ->
        assert opts[:json] == %{"Code" => "export default {}"}
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.EdgeScript.set_code(client, 1, "export default {}")
    end
  end
end
