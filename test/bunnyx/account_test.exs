defmodule Bunnyx.AccountTest do
  use ExUnit.Case, async: true
  use Mimic

  setup do
    %{client: Bunnyx.new(api_key: "sk-test")}
  end

  describe "affiliate/1" do
    test "returns affiliate details", %{client: client} do
      response = %{"AffiliateBalance" => 25.0, "AffiliateUrl" => "https://bunny.net?ref=abc"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/billing/affiliate", _opts ->
        {:ok, response}
      end)

      assert {:ok, %{"AffiliateBalance" => 25.0}} = Bunnyx.Account.affiliate(client)
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 401, message: "Unauthorized"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/billing/affiliate", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.Account.affiliate(client)
    end
  end

  describe "audit_log/3" do
    test "returns audit log for date", %{client: client} do
      response = %{"Items" => [%{"Action" => "Create"}]}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/user/audit/2025-06-01", opts ->
        assert opts[:params] == %{}
        {:ok, response}
      end)

      assert {:ok, %{"Items" => _}} = Bunnyx.Account.audit_log(client, ~D[2025-06-01])
    end

    test "passes filter params", %{client: client} do
      response = %{"Items" => []}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/user/audit/2025-06-01", opts ->
        assert opts[:params]["Order"] == "Descending"
        assert opts[:params]["Limit"] == 100
        {:ok, response}
      end)

      Bunnyx.Account.audit_log(client, "2025-06-01", order: "Descending", limit: 100)
    end
  end

  describe "search/3" do
    test "returns search results", %{client: client} do
      response = %{"Results" => [%{"Name" => "my-zone"}]}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/search", opts ->
        assert opts[:params]["search"] == "my-zone"
        {:ok, response}
      end)

      assert {:ok, %{"Results" => _}} = Bunnyx.Account.search(client, "my-zone")
    end

    test "passes pagination params", %{client: client} do
      response = %{"Results" => []}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/search", opts ->
        assert opts[:params]["from"] == 20
        assert opts[:params]["size"] == 10
        {:ok, response}
      end)

      Bunnyx.Account.search(client, "test", from: 20, size: 10)
    end
  end

  describe "close_account/2" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :post, "/user/closeaccount", _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.Account.close_account(client)
    end
  end
end
