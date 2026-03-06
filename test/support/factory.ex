defmodule Bunnyx.Factory do
  @moduledoc false

  def pull_zone_response(overrides \\ %{}) do
    Map.merge(
      %{
        "Id" => 12_345,
        "Name" => "my-zone",
        "OriginUrl" => "https://example.com",
        "Enabled" => true,
        "Suspended" => false,
        "Hostnames" => [],
        "StorageZoneId" => 0,
        "MonthlyBandwidthLimit" => 0,
        "MonthlyBandwidthUsed" => 1024,
        "CacheControlMaxAgeOverride" => -1,
        "IgnoreQueryStrings" => true,
        "Type" => 0
      },
      overrides
    )
  end

  def pull_zone_list_response(overrides \\ %{}) do
    Map.merge(
      %{
        "Items" => [pull_zone_response()],
        "CurrentPage" => 1,
        "TotalItems" => 1,
        "HasMoreItems" => false
      },
      overrides
    )
  end
end
