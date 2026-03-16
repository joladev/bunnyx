defmodule Bunnyx.ApiKeyTest do
  use ExUnit.Case, async: true
  use Mimic

  setup do
    %{client: Bunnyx.new(api_key: "sk-test")}
  end

  describe "list/2" do
    test "returns parsed API keys", %{client: client} do
      response = %{
        "Items" => [
          %{"Id" => 1, "Key" => "sk-abc123", "Roles" => ["admin"]}
        ],
        "CurrentPage" => 1,
        "TotalItems" => 1,
        "HasMoreItems" => false
      }

      expect(Bunnyx.HTTP, :request, fn req, :get, "/apikey", opts ->
        assert req == client.req
        assert opts[:params] == %{}
        {:ok, response}
      end)

      assert {:ok, page} = Bunnyx.ApiKey.list(client)
      assert [%{id: 1, key: "sk-abc123", roles: ["admin"]}] = page.items
      assert page.current_page == 1
      assert page.total_items == 1
      assert page.has_more_items == false
    end

    test "passes query params", %{client: client} do
      response = %{
        "Items" => [],
        "CurrentPage" => 2,
        "TotalItems" => 0,
        "HasMoreItems" => false
      }

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/apikey", opts ->
        assert opts[:params] == %{"page" => 2, "perPage" => 10}
        {:ok, response}
      end)

      Bunnyx.ApiKey.list(client, page: 2, per_page: 10)
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 401, message: "Unauthorized"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/apikey", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.ApiKey.list(client)
    end
  end
end
