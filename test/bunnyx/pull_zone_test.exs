defmodule Bunnyx.PullZoneTest do
  use ExUnit.Case, async: true
  use Mimic

  setup do
    %{client: Bunnyx.new(api_key: "sk-test")}
  end

  describe "list/2" do
    test "returns parsed pull zones", %{client: client} do
      response = Bunnyx.Factory.pull_zone_list_response()

      expect(Bunnyx.HTTP, :request, fn req, :get, "/pullzone", opts ->
        assert req == client.req
        assert opts[:params] == %{}
        {:ok, response}
      end)

      assert {:ok, page} = Bunnyx.PullZone.list(client)
      assert [%Bunnyx.PullZone{id: 12_345, name: "my-zone"}] = page.items
      assert page.current_page == 1
      assert page.total_items == 1
      assert page.has_more_items == false
    end

    test "passes query params", %{client: client} do
      response = Bunnyx.Factory.pull_zone_list_response()

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/pullzone", opts ->
        assert opts[:params] == %{"page" => 2, "perPage" => 10, "search" => "test"}
        {:ok, response}
      end)

      Bunnyx.PullZone.list(client, page: 2, per_page: 10, search: "test")
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 500, message: "Server error"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/pullzone", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.PullZone.list(client)
    end
  end

  describe "get/2" do
    test "returns parsed pull zone", %{client: client} do
      response = Bunnyx.Factory.pull_zone_response()

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/pullzone/12345", _opts ->
        {:ok, response}
      end)

      assert {:ok,
              %Bunnyx.PullZone{id: 12_345, name: "my-zone", origin_url: "https://example.com"}} =
               Bunnyx.PullZone.get(client, 12_345)
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 404, message: "Not found"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/pullzone/999", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.PullZone.get(client, 999)
    end
  end

  describe "create/2" do
    test "sends attrs and returns parsed pull zone", %{client: client} do
      response = Bunnyx.Factory.pull_zone_response(%{"Name" => "new-zone"})

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/pullzone", opts ->
        assert opts[:body] == %{"Name" => "new-zone", "OriginUrl" => "https://example.com"}
        {:ok, response}
      end)

      assert {:ok, %Bunnyx.PullZone{name: "new-zone"}} =
               Bunnyx.PullZone.create(client, name: "new-zone", origin_url: "https://example.com")
    end
  end

  describe "update/3" do
    test "sends attrs to correct path", %{client: client} do
      response = Bunnyx.Factory.pull_zone_response(%{"CacheControlMaxAgeOverride" => 3600})

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/pullzone/12345", opts ->
        assert opts[:body] == %{"CacheControlMaxAgeOverride" => 3600}
        {:ok, response}
      end)

      assert {:ok, %Bunnyx.PullZone{cache_control_max_age_override: 3600}} =
               Bunnyx.PullZone.update(client, 12_345, cache_control_max_age_override: 3600)
    end
  end

  describe "delete/2" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :delete, "/pullzone/12345", _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.PullZone.delete(client, 12_345)
    end
  end

  describe "resolve" do
    test "accepts keyword list as client" do
      response = Bunnyx.Factory.pull_zone_response()

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/pullzone/1", _opts ->
        {:ok, response}
      end)

      assert {:ok, %Bunnyx.PullZone{}} = Bunnyx.PullZone.get([api_key: "sk-test"], 1)
    end
  end
end
