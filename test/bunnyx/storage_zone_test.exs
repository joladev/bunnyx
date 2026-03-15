defmodule Bunnyx.StorageZoneTest do
  use ExUnit.Case, async: true
  use Mimic

  setup do
    %{client: Bunnyx.new(api_key: "sk-test")}
  end

  describe "list/2" do
    test "returns parsed storage zones", %{client: client} do
      response = Bunnyx.Factory.storage_zone_list_response()

      expect(Bunnyx.HTTP, :request, fn req, :get, "/storagezone", opts ->
        assert req == client.req
        assert opts[:params] == %{}
        {:ok, response}
      end)

      assert {:ok, page} = Bunnyx.StorageZone.list(client)
      assert [%Bunnyx.StorageZone{id: 80_001, name: "my-zone"}] = page.items
      assert page.current_page == 1
      assert page.total_items == 1
      assert page.has_more_items == false
    end

    test "passes query params", %{client: client} do
      response = Bunnyx.Factory.storage_zone_list_response()

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/storagezone", opts ->
        assert opts[:params] == %{
                 "page" => 2,
                 "perPage" => 10,
                 "search" => "test",
                 "includeDeleted" => true
               }

        {:ok, response}
      end)

      Bunnyx.StorageZone.list(client,
        page: 2,
        per_page: 10,
        search: "test",
        include_deleted: true
      )
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 500, message: "Server error"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/storagezone", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.StorageZone.list(client)
    end
  end

  describe "get/2" do
    test "returns parsed storage zone", %{client: client} do
      response = Bunnyx.Factory.storage_zone_response()

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/storagezone/80001", _opts ->
        {:ok, response}
      end)

      assert {:ok, %Bunnyx.StorageZone{id: 80_001, name: "my-zone", region: "DE"}} =
               Bunnyx.StorageZone.get(client, 80_001)
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 404, message: "Not found"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/storagezone/999", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.StorageZone.get(client, 999)
    end
  end

  describe "create/2" do
    test "sends attrs and returns parsed storage zone", %{client: client} do
      response = Bunnyx.Factory.storage_zone_response(%{"Name" => "new-zone"})

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/storagezone", opts ->
        assert opts[:json] == %{"Name" => "new-zone", "Region" => "DE"}
        {:ok, response}
      end)

      assert {:ok, %Bunnyx.StorageZone{name: "new-zone"}} =
               Bunnyx.StorageZone.create(client, name: "new-zone", region: "DE")
    end
  end

  describe "update/3" do
    test "sends attrs to correct path", %{client: client} do
      response = Bunnyx.Factory.storage_zone_response(%{"Rewrite404To200" => true})

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/storagezone/80001", opts ->
        assert opts[:json] == %{"Rewrite404To200" => true}
        {:ok, response}
      end)

      assert {:ok, %Bunnyx.StorageZone{rewrite_404_to_200: true}} =
               Bunnyx.StorageZone.update(client, 80_001, rewrite_404_to_200: true)
    end
  end

  describe "delete/2" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :delete, "/storagezone/80001", _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.StorageZone.delete(client, 80_001)
    end
  end

  describe "statistics/3" do
    test "returns parsed chart maps", %{client: client} do
      response = %{
        "StorageUsedChart" => %{"2025-06-01" => 1024, "2025-06-02" => 2048},
        "FileCountChart" => %{"2025-06-01" => 10, "2025-06-02" => 20}
      }

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/storagezone/80001/statistics", opts ->
        assert opts[:params] == %{}
        {:ok, response}
      end)

      assert {:ok, stats} = Bunnyx.StorageZone.statistics(client, 80_001)
      assert stats.storage_used_chart == %{"2025-06-01" => 1024, "2025-06-02" => 2048}
      assert stats.file_count_chart == %{"2025-06-01" => 10, "2025-06-02" => 20}
    end

    test "passes date params", %{client: client} do
      response = %{"StorageUsedChart" => %{}, "FileCountChart" => %{}}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/storagezone/80001/statistics", opts ->
        assert opts[:params] == %{"dateFrom" => "2025-06-01", "dateTo" => "2025-06-30"}
        {:ok, response}
      end)

      Bunnyx.StorageZone.statistics(client, 80_001,
        date_from: "2025-06-01",
        date_to: "2025-06-30"
      )
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 500, message: "Server error"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/storagezone/80001/statistics", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.StorageZone.statistics(client, 80_001)
    end
  end

  describe "reset_password/2" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :post, "/storagezone/80001/resetPassword", _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.StorageZone.reset_password(client, 80_001)
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 500, message: "Server error"}

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/storagezone/80001/resetPassword", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.StorageZone.reset_password(client, 80_001)
    end
  end

  describe "reset_read_only_password/2" do
    test "sends id as query param and returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :post, "/storagezone/resetReadOnlyPassword", opts ->
        assert opts[:params] == %{"id" => 80_001}
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.StorageZone.reset_read_only_password(client, 80_001)
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 500, message: "Server error"}

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/storagezone/resetReadOnlyPassword", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.StorageZone.reset_read_only_password(client, 80_001)
    end
  end

  describe "check_availability/2" do
    test "sends name and returns availability", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :post, "/storagezone/checkavailability", opts ->
        assert opts[:json] == %{"Name" => "my-zone"}
        {:ok, %{"Available" => true}}
      end)

      assert {:ok, true} = Bunnyx.StorageZone.check_availability(client, "my-zone")
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 400, message: "Bad request"}

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/storagezone/checkavailability", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.StorageZone.check_availability(client, "my-zone")
    end
  end

  describe "resolve" do
    test "accepts keyword list as client" do
      response = Bunnyx.Factory.storage_zone_response()

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/storagezone/1", _opts ->
        {:ok, response}
      end)

      assert {:ok, %Bunnyx.StorageZone{}} = Bunnyx.StorageZone.get([api_key: "sk-test"], 1)
    end
  end
end
