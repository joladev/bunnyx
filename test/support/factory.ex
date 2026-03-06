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

  def storage_object_response(overrides \\ %{}) do
    Map.merge(
      %{
        "Guid" => "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
        "StorageZoneName" => "my-zone",
        "Path" => "/my-zone/images/",
        "ObjectName" => "logo.png",
        "Length" => 1024,
        "LastChanged" => "2025-01-15T10:30:00.000",
        "IsDirectory" => false,
        "ContentType" => "image/png",
        "DateCreated" => "2025-01-10T08:00:00.000",
        "Checksum" => "ABC123"
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
