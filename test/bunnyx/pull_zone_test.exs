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
        assert opts[:json] == %{"Name" => "new-zone", "OriginUrl" => "https://example.com"}
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
        assert opts[:json] == %{"CacheControlMaxAgeOverride" => 3600}
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

  describe "add_hostname/3" do
    test "sends hostname and returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :post, "/pullzone/12345/addHostname", opts ->
        assert opts[:json] == %{"Hostname" => "cdn.example.com"}
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.PullZone.add_hostname(client, 12_345, "cdn.example.com")
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 400, message: "Bad request"}

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/pullzone/12345/addHostname", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.PullZone.add_hostname(client, 12_345, "cdn.example.com")
    end
  end

  describe "remove_hostname/3" do
    test "sends hostname and returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :delete, "/pullzone/12345/removeHostname", opts ->
        assert opts[:json] == %{"Hostname" => "cdn.example.com"}
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.PullZone.remove_hostname(client, 12_345, "cdn.example.com")
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 400, message: "Bad request"}

      expect(Bunnyx.HTTP, :request, fn _req, :delete, "/pullzone/12345/removeHostname", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.PullZone.remove_hostname(client, 12_345, "cdn.example.com")
    end
  end

  describe "add_blocked_ip/3" do
    test "sends IP and returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :post, "/pullzone/12345/addBlockedIp", opts ->
        assert opts[:json] == %{"Value" => "1.2.3.4"}
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.PullZone.add_blocked_ip(client, 12_345, "1.2.3.4")
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 400, message: "Bad request"}

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/pullzone/12345/addBlockedIp", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.PullZone.add_blocked_ip(client, 12_345, "1.2.3.4")
    end
  end

  describe "remove_blocked_ip/3" do
    test "sends IP and returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :post, "/pullzone/12345/removeBlockedIp", opts ->
        assert opts[:json] == %{"Value" => "1.2.3.4"}
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.PullZone.remove_blocked_ip(client, 12_345, "1.2.3.4")
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 400, message: "Bad request"}

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/pullzone/12345/removeBlockedIp", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.PullZone.remove_blocked_ip(client, 12_345, "1.2.3.4")
    end
  end

  describe "reset_security_key/2" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :post, "/pullzone/12345/resetSecurityKey", _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.PullZone.reset_security_key(client, 12_345)
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 500, message: "Server error"}

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/pullzone/12345/resetSecurityKey", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.PullZone.reset_security_key(client, 12_345)
    end
  end

  describe "check_availability/2" do
    test "returns {:ok, nil} when available", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :post, "/pullzone/checkavailability", opts ->
        assert opts[:json] == %{"Name" => "my-zone"}
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.PullZone.check_availability(client, "my-zone")
    end

    test "returns error when unavailable", %{client: client} do
      error = %Bunnyx.Error{status: 400, message: "Name already taken"}

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/pullzone/checkavailability", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.PullZone.check_availability(client, "taken-zone")
    end
  end

  describe "optimizer_statistics/3" do
    test "returns parsed statistics", %{client: client} do
      response = %{
        "RequestsOptimizedChart" => %{"2025-06-01" => 100},
        "AverageCompressionChart" => %{"2025-06-01" => 50},
        "TrafficSavedChart" => %{"2025-06-01" => 200},
        "AverageProcessingTimeChart" => %{"2025-06-01" => 10},
        "TotalRequestsOptimized" => 100,
        "TotalTrafficSaved" => 200,
        "AverageProcessingTime" => 10.5,
        "AverageCompressionRatio" => 0.65
      }

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/pullzone/12345/optimizer/statistics", opts ->
        assert opts[:params] == %{}
        {:ok, response}
      end)

      assert {:ok, stats} = Bunnyx.PullZone.optimizer_statistics(client, 12_345)
      assert stats.total_requests_optimized == 100
      assert stats.average_compression_ratio == 0.65
    end

    test "passes date and hourly params", %{client: client} do
      response = %{
        "RequestsOptimizedChart" => %{},
        "AverageCompressionChart" => %{},
        "TrafficSavedChart" => %{},
        "AverageProcessingTimeChart" => %{},
        "TotalRequestsOptimized" => 0,
        "TotalTrafficSaved" => 0,
        "AverageProcessingTime" => 0,
        "AverageCompressionRatio" => 0
      }

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/pullzone/12345/optimizer/statistics", opts ->
        assert opts[:params] == %{
                 "dateFrom" => "2025-06-01",
                 "dateTo" => "2025-06-30",
                 "hourly" => true
               }

        {:ok, response}
      end)

      Bunnyx.PullZone.optimizer_statistics(client, 12_345,
        date_from: "2025-06-01",
        date_to: "2025-06-30",
        hourly: true
      )
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 500, message: "Server error"}

      expect(Bunnyx.HTTP, :request, fn _req,
                                       :get,
                                       "/pullzone/12345/optimizer/statistics",
                                       _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.PullZone.optimizer_statistics(client, 12_345)
    end
  end

  describe "safehop_statistics/3" do
    test "returns parsed statistics", %{client: client} do
      response = %{
        "RequestsRetriedChart" => %{"2025-06-01" => 10},
        "RequestsSavedChart" => %{"2025-06-01" => 90},
        "TotalRequestsRetried" => 10,
        "TotalRequestsSaved" => 90
      }

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/pullzone/12345/safehop/statistics", _opts ->
        {:ok, response}
      end)

      assert {:ok, stats} = Bunnyx.PullZone.safehop_statistics(client, 12_345)
      assert stats.total_requests_retried == 10
      assert stats.total_requests_saved == 90
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 500, message: "Server error"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/pullzone/12345/safehop/statistics", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.PullZone.safehop_statistics(client, 12_345)
    end
  end

  describe "origin_shield_statistics/3" do
    test "returns parsed statistics", %{client: client} do
      response = %{
        "ConcurrentRequestsChart" => %{"2025-06-01" => 50},
        "QueuedRequestsChart" => %{"2025-06-01" => 5}
      }

      expect(Bunnyx.HTTP, :request, fn _req,
                                       :get,
                                       "/pullzone/12345/originshield/queuestatistics",
                                       _opts ->
        {:ok, response}
      end)

      assert {:ok, stats} = Bunnyx.PullZone.origin_shield_statistics(client, 12_345)
      assert stats.concurrent_requests_chart == %{"2025-06-01" => 50}
      assert stats.queued_requests_chart == %{"2025-06-01" => 5}
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 500, message: "Server error"}

      expect(Bunnyx.HTTP, :request, fn _req,
                                       :get,
                                       "/pullzone/12345/originshield/queuestatistics",
                                       _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.PullZone.origin_shield_statistics(client, 12_345)
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
