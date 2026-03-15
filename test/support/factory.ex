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

  def dns_record_response(overrides \\ %{}) do
    Map.merge(
      %{
        "Id" => 99_001,
        "Type" => 0,
        "Ttl" => 300,
        "Value" => "1.2.3.4",
        "Name" => "www",
        "Weight" => 0,
        "Priority" => 0,
        "Port" => 0,
        "Flags" => 0,
        "Tag" => "",
        "Accelerated" => false,
        "Disabled" => false,
        "Comment" => ""
      },
      overrides
    )
  end

  def dns_zone_response(overrides \\ %{}) do
    Map.merge(
      %{
        "Id" => 50_001,
        "Domain" => "example.com",
        "Records" => [dns_record_response()],
        "DateModified" => "2025-06-01T12:00:00Z",
        "DateCreated" => "2025-01-01T00:00:00Z",
        "NameserversDetected" => true,
        "CustomNameserversEnabled" => false,
        "Nameserver1" => "ns1.bunny.net",
        "Nameserver2" => "ns2.bunny.net",
        "SoaEmail" => "admin@example.com",
        "NameserversNextCheck" => "2025-06-02T00:00:00Z",
        "LoggingEnabled" => false,
        "LoggingIPAnonymizationEnabled" => false,
        "LogAnonymizationType" => 0,
        "DnsSecEnabled" => false,
        "CertificateKeyType" => 0
      },
      overrides
    )
  end

  def storage_zone_response(overrides \\ %{}) do
    Map.merge(
      %{
        "Id" => 80_001,
        "Name" => "my-zone",
        "Password" => "pw-abc123",
        "ReadOnlyPassword" => "pw-readonly-123",
        "DateModified" => "2025-06-01T12:00:00Z",
        "Deleted" => false,
        "StorageUsed" => 1_073_741_824,
        "FilesStored" => 500,
        "Region" => "DE",
        "ReplicationRegions" => ["NY"],
        "StorageHostname" => "storage.bunnycdn.com",
        "Rewrite404To200" => false,
        "Custom404FilePath" => "",
        "ZoneTier" => 0
      },
      overrides
    )
  end

  def storage_zone_list_response(overrides \\ %{}) do
    Map.merge(
      %{
        "Items" => [storage_zone_response()],
        "CurrentPage" => 1,
        "TotalItems" => 1,
        "HasMoreItems" => false
      },
      overrides
    )
  end

  def dns_zone_list_response(overrides \\ %{}) do
    Map.merge(
      %{
        "Items" => [dns_zone_response()],
        "CurrentPage" => 1,
        "TotalItems" => 1,
        "HasMoreItems" => false
      },
      overrides
    )
  end
end
