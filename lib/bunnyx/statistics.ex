defmodule Bunnyx.Statistics do
  @moduledoc """
  Account-wide statistics — bandwidth, cache hit rates, requests, origin traffic,
  and error breakdowns.

  This is distinct from per-resource statistics on PullZone, StorageZone, and DnsZone.

  Uses the main API client created with `Bunnyx.new/1`.

  ## Usage

      client = Bunnyx.new(api_key: "sk-...")

      {:ok, stats} = Bunnyx.Statistics.get(client,
        date_from: "2025-06-01T00:00:00Z",
        date_to: "2025-06-30T23:59:59Z"
      )
  """

  @response_mapping %{
    "TotalBandwidthUsed" => :total_bandwidth_used,
    "TotalOriginTraffic" => :total_origin_traffic,
    "AverageOriginResponseTime" => :average_origin_response_time,
    "TotalRequestsServed" => :total_requests_served,
    "CacheHitRate" => :cache_hit_rate,
    "BandwidthUsedChart" => :bandwidth_used_chart,
    "BandwidthCachedChart" => :bandwidth_cached_chart,
    "CacheHitRateChart" => :cache_hit_rate_chart,
    "RequestsServedChart" => :requests_served_chart,
    "PullRequestsPulledChart" => :pull_requests_pulled_chart,
    "OriginResponseTimeChart" => :origin_response_time_chart,
    "OriginShieldBandwidthUsedChart" => :origin_shield_bandwidth_used_chart,
    "OriginShieldInternalBandwidthUsedChart" => :origin_shield_internal_bandwidth_used_chart,
    "OriginTrafficChart" => :origin_traffic_chart,
    "UserBalanceHistoryChart" => :user_balance_history_chart,
    "GeoTrafficDistribution" => :geo_traffic_distribution,
    "Error3xxChart" => :error_3xx_chart,
    "Error4xxChart" => :error_4xx_chart,
    "Error5xxChart" => :error_5xx_chart
  }

  @doc """
  Returns account-wide statistics.

  ## Options

    * `:date_from` — start date (ISO 8601 string)
    * `:date_to` — end date (ISO 8601 string)
    * `:pull_zone` — filter by pull zone ID
    * `:server_zone_id` — filter by server zone / region ID
    * `:hourly` — group by hour instead of day
    * `:load_errors` — include 3xx/4xx/5xx error charts
    * `:load_origin_response_times` — include origin response time chart
    * `:load_origin_traffic` — include origin traffic chart
    * `:load_requests_served` — include requests served chart
    * `:load_bandwidth_used` — include bandwidth used chart
    * `:load_origin_shield_bandwidth` — include origin shield bandwidth chart
    * `:load_geographic_traffic_distribution` — include geo traffic distribution
    * `:load_user_balance_history` — include user balance history chart

  """
  @spec get(Bunnyx.t() | keyword(), keyword()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def get(client, opts \\ []) do
    client = Bunnyx.resolve(client)
    params = to_params(opts)

    case Bunnyx.HTTP.request(client.req, :get, "/statistics", params: params) do
      {:ok, body} -> {:ok, from_response(body)}
      {:error, _} = error -> error
    end
  end

  defp from_response(data) when is_map(data) do
    for {pascal, atom} <- @response_mapping, Map.has_key?(data, pascal), into: %{} do
      {atom, data[pascal]}
    end
  end

  @param_mapping %{
    date_from: "dateFrom",
    date_to: "dateTo",
    pull_zone: "pullZone",
    server_zone_id: "serverZoneId",
    hourly: "hourly",
    load_errors: "loadErrors",
    load_origin_response_times: "loadOriginResponseTimes",
    load_origin_traffic: "loadOriginTraffic",
    load_requests_served: "loadRequestsServed",
    load_bandwidth_used: "loadBandwidthUsed",
    load_origin_shield_bandwidth: "loadOriginShieldBandwidth",
    load_geographic_traffic_distribution: "loadGeographicTrafficDistribution",
    load_user_balance_history: "loadUserBalanceHistory"
  }

  defp to_params(opts) do
    Map.new(opts, fn {key, value} ->
      {Map.fetch!(@param_mapping, key), value}
    end)
  end
end
