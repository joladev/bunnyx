defmodule Bunnyx.StatisticsTest do
  use ExUnit.Case, async: true
  use Mimic

  setup do
    %{client: Bunnyx.new(api_key: "sk-test")}
  end

  describe "get/2" do
    test "returns parsed statistics", %{client: client} do
      response = %{
        "TotalBandwidthUsed" => 1_073_741_824,
        "TotalRequestsServed" => 50_000,
        "CacheHitRate" => 0.95,
        "BandwidthUsedChart" => %{"2025-06-01" => 500_000},
        "RequestsServedChart" => %{"2025-06-01" => 25_000}
      }

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/statistics", opts ->
        assert opts[:params] == %{}
        {:ok, response}
      end)

      assert {:ok, stats} = Bunnyx.Statistics.get(client)
      assert stats.total_bandwidth_used == 1_073_741_824
      assert stats.total_requests_served == 50_000
      assert stats.cache_hit_rate == 0.95
      assert stats.bandwidth_used_chart == %{"2025-06-01" => 500_000}
    end

    test "passes query params", %{client: client} do
      response = %{"TotalBandwidthUsed" => 0, "TotalRequestsServed" => 0, "CacheHitRate" => 0}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/statistics", opts ->
        assert opts[:params] == %{
                 "dateFrom" => "2025-06-01",
                 "dateTo" => "2025-06-30",
                 "pullZone" => 12_345,
                 "hourly" => true,
                 "loadErrors" => true
               }

        {:ok, response}
      end)

      Bunnyx.Statistics.get(client,
        date_from: "2025-06-01",
        date_to: "2025-06-30",
        pull_zone: 12_345,
        hourly: true,
        load_errors: true
      )
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 500, message: "Server error"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/statistics", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.Statistics.get(client)
    end
  end
end
