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

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 500, message: "Server error"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/compute/script", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.EdgeScript.list(client)
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

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 404, message: "Not found"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/compute/script/999", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.EdgeScript.get(client, 999)
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

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 400, message: "Bad request"}

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/compute/script", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.EdgeScript.create(client, name: "bad", script_type: 1)
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

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 500, message: "Server error"}

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/compute/script/1", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.EdgeScript.update(client, 1, name: "bad")
    end
  end

  describe "delete/2" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :delete, "/compute/script/1", _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.EdgeScript.delete(client, 1)
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 404, message: "Not found"}

      expect(Bunnyx.HTTP, :request, fn _req, :delete, "/compute/script/1", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.EdgeScript.delete(client, 1)
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

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 500, message: "Server error"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/compute/script/1/statistics", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.EdgeScript.statistics(client, 1)
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

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 404, message: "Not found"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/compute/script/1/code", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.EdgeScript.get_code(client, 1)
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

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 500, message: "Server error"}

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/compute/script/1/code", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.EdgeScript.set_code(client, 1, "bad code")
    end
  end

  # -- Releases --

  describe "list_releases/3" do
    test "returns releases", %{client: client} do
      response = %{"Items" => [%{"Uuid" => "r-1"}]}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/compute/script/1/releases", _opts ->
        {:ok, response}
      end)

      assert {:ok, %{"Items" => _}} = Bunnyx.EdgeScript.list_releases(client, 1)
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 500, message: "Server error"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/compute/script/1/releases", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.EdgeScript.list_releases(client, 1)
    end
  end

  describe "get_active_release/2" do
    test "returns active release", %{client: client} do
      response = %{"Uuid" => "r-1", "Status" => "Active"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/compute/script/1/releases/active", _opts ->
        {:ok, response}
      end)

      assert {:ok, %{"Uuid" => "r-1"}} = Bunnyx.EdgeScript.get_active_release(client, 1)
    end
  end

  describe "publish_release/3" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :post, "/compute/script/1/publish", opts ->
        assert opts[:json]["Note"] == "v1.0"
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.EdgeScript.publish_release(client, 1, note: "v1.0")
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 500, message: "Server error"}

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/compute/script/1/publish", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.EdgeScript.publish_release(client, 1)
    end
  end

  # -- Secrets --

  describe "list_secrets/2" do
    test "returns secrets", %{client: client} do
      response = [%{"Name" => "API_KEY"}]

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/compute/script/1/secrets", _opts ->
        {:ok, response}
      end)

      assert {:ok, [%{"Name" => "API_KEY"}]} = Bunnyx.EdgeScript.list_secrets(client, 1)
    end
  end

  describe "add_secret/4" do
    test "sends name and secret", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :post, "/compute/script/1/secrets", opts ->
        assert opts[:json] == %{"Name" => "API_KEY", "Secret" => "sk-123"}
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.EdgeScript.add_secret(client, 1, "API_KEY", "sk-123")
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 400, message: "Bad request"}

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/compute/script/1/secrets", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.EdgeScript.add_secret(client, 1, "KEY", "val")
    end
  end

  describe "upsert_secret/4" do
    test "sends upsert", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :put, "/compute/script/1/secrets", opts ->
        assert opts[:json] == %{"Name" => "API_KEY", "Secret" => "sk-456"}
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.EdgeScript.upsert_secret(client, 1, "API_KEY", "sk-456")
    end
  end

  describe "update_secret/4" do
    test "sends updated value", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :post, "/compute/script/1/secrets/API_KEY", opts ->
        assert opts[:json] == %{"Secret" => "sk-789"}
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.EdgeScript.update_secret(client, 1, "API_KEY", "sk-789")
    end
  end

  describe "delete_secret/3" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :delete, "/compute/script/1/secrets/42", _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.EdgeScript.delete_secret(client, 1, 42)
    end
  end

  # -- Variables --

  describe "get_variable/3" do
    test "returns variable", %{client: client} do
      response = %{"Name" => "PORT", "DefaultValue" => "8080"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/compute/script/1/variables/42", _opts ->
        {:ok, response}
      end)

      assert {:ok, %{"Name" => "PORT"}} = Bunnyx.EdgeScript.get_variable(client, 1, 42)
    end
  end

  describe "add_variable/3" do
    test "sends variable attrs", %{client: client} do
      response = %{"Id" => 42, "Name" => "PORT", "Required" => true, "DefaultValue" => "8080"}

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/compute/script/1/variables/add", opts ->
        assert opts[:json] == %{"Name" => "PORT", "Required" => true, "DefaultValue" => "8080"}
        {:ok, response}
      end)

      assert {:ok, %{"Id" => 42}} =
               Bunnyx.EdgeScript.add_variable(client, 1,
                 name: "PORT",
                 required: true,
                 default_value: "8080"
               )
    end
  end

  describe "upsert_variable/3" do
    test "sends upsert", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :put, "/compute/script/1/variables", opts ->
        assert opts[:json]["Name"] == "PORT"
        {:ok, ""}
      end)

      assert {:ok, nil} =
               Bunnyx.EdgeScript.upsert_variable(client, 1, name: "PORT", required: true)
    end
  end

  describe "update_variable/4" do
    test "sends updated attrs", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :post, "/compute/script/1/variables/42", opts ->
        assert opts[:json]["DefaultValue"] == "9090"
        {:ok, ""}
      end)

      assert {:ok, nil} =
               Bunnyx.EdgeScript.update_variable(client, 1, 42, default_value: "9090")
    end
  end

  describe "delete_variable/3" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :delete, "/compute/script/1/variables/42", _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.EdgeScript.delete_variable(client, 1, 42)
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 404, message: "Not found"}

      expect(Bunnyx.HTTP, :request, fn _req, :delete, "/compute/script/1/variables/42", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.EdgeScript.delete_variable(client, 1, 42)
    end
  end
end
