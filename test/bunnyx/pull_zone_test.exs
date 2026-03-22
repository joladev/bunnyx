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
        assert opts[:json] == %{"BlockedIp" => "1.2.3.4"}
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
        assert opts[:json] == %{"BlockedIp" => "1.2.3.4"}
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
    test "returns {:ok, true} when available", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :post, "/pullzone/checkavailability", opts ->
        assert opts[:json] == %{"Name" => "my-zone"}
        {:ok, %{"Available" => true}}
      end)

      assert {:ok, true} = Bunnyx.PullZone.check_availability(client, "my-zone")
    end

    test "returns {:ok, false} when taken", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :post, "/pullzone/checkavailability", _opts ->
        {:ok, %{"Available" => false}}
      end)

      assert {:ok, false} = Bunnyx.PullZone.check_availability(client, "taken-zone")
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

  describe "add_or_update_edge_rule/3" do
    test "sends edge rule attrs and returns {:ok, nil}", %{client: client} do
      triggers = [%{"Type" => 0, "PatternMatchingType" => 0, "PatternMatches" => ["*.jpg"]}]

      expect(Bunnyx.HTTP, :request, fn _req,
                                       :post,
                                       "/pullzone/12345/edgerules/addOrUpdate",
                                       opts ->
        assert opts[:json] == %{
                 "ActionType" => 1,
                 "ActionParameter1" => "https://example.com",
                 "TriggerMatchingType" => 0,
                 "Triggers" => triggers,
                 "Description" => "Redirect rule",
                 "Enabled" => true
               }

        {:ok, ""}
      end)

      assert {:ok, nil} =
               Bunnyx.PullZone.add_or_update_edge_rule(client, 12_345,
                 action_type: 1,
                 action_parameter_1: "https://example.com",
                 trigger_matching_type: 0,
                 triggers: triggers,
                 description: "Redirect rule",
                 enabled: true
               )
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 400, message: "Bad request"}

      expect(Bunnyx.HTTP, :request, fn _req,
                                       :post,
                                       "/pullzone/12345/edgerules/addOrUpdate",
                                       _opts ->
        {:error, error}
      end)

      assert {:error, ^error} =
               Bunnyx.PullZone.add_or_update_edge_rule(client, 12_345, action_type: 1)
    end
  end

  describe "delete_edge_rule/3" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req,
                                       :delete,
                                       "/pullzone/12345/edgerules/abc-123",
                                       _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.PullZone.delete_edge_rule(client, 12_345, "abc-123")
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 404, message: "Not found"}

      expect(Bunnyx.HTTP, :request, fn _req,
                                       :delete,
                                       "/pullzone/12345/edgerules/abc-123",
                                       _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.PullZone.delete_edge_rule(client, 12_345, "abc-123")
    end
  end

  describe "set_edge_rule_enabled/4" do
    test "sends toggle and returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req,
                                       :post,
                                       "/pullzone/12345/edgerules/abc-123/setEdgeRuleEnabled",
                                       opts ->
        assert opts[:json] == %{"Id" => 12_345, "Value" => true}
        {:ok, ""}
      end)

      assert {:ok, nil} =
               Bunnyx.PullZone.set_edge_rule_enabled(client, 12_345, "abc-123", true)
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 500, message: "Server error"}

      expect(Bunnyx.HTTP, :request, fn _req,
                                       :post,
                                       "/pullzone/12345/edgerules/abc-123/setEdgeRuleEnabled",
                                       _opts ->
        {:error, error}
      end)

      assert {:error, ^error} =
               Bunnyx.PullZone.set_edge_rule_enabled(client, 12_345, "abc-123", false)
    end
  end

  describe "update_private_key_type/4" do
    test "sends hostname and key type", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req,
                                       :post,
                                       "/pullzone/12345/updatePrivateKeyType",
                                       opts ->
        assert opts[:json] == %{"Hostname" => "cdn.example.com", "KeyType" => 0}
        {:ok, ""}
      end)

      assert {:ok, nil} =
               Bunnyx.PullZone.update_private_key_type(client, 12_345, "cdn.example.com", 0)
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 404, message: "Not found"}

      expect(Bunnyx.HTTP, :request, fn _req,
                                       :post,
                                       "/pullzone/12345/updatePrivateKeyType",
                                       _opts ->
        {:error, error}
      end)

      assert {:error, ^error} =
               Bunnyx.PullZone.update_private_key_type(client, 12_345, "cdn.example.com", 1)
    end
  end

  describe "load_free_certificate/2" do
    test "sends hostname and returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :get, "/pullzone/loadFreeCertificate", opts ->
        assert opts[:params] == %{"hostname" => "cdn.example.com"}
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.PullZone.load_free_certificate(client, "cdn.example.com")
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 400, message: "Bad request"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/pullzone/loadFreeCertificate", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.PullZone.load_free_certificate(client, "cdn.example.com")
    end
  end

  describe "set_force_ssl/4" do
    test "sends hostname and flag", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :post, "/pullzone/12345/setForceSSL", opts ->
        assert opts[:json] == %{"Hostname" => "cdn.example.com", "ForceSSL" => true}
        {:ok, ""}
      end)

      assert {:ok, nil} =
               Bunnyx.PullZone.set_force_ssl(client, 12_345, "cdn.example.com", true)
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 400, message: "Bad request"}

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/pullzone/12345/setForceSSL", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} =
               Bunnyx.PullZone.set_force_ssl(client, 12_345, "cdn.example.com", true)
    end
  end

  describe "add_certificate/5" do
    test "sends certificate data and returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :post, "/pullzone/12345/addCertificate", opts ->
        assert opts[:json] == %{
                 "Hostname" => "cdn.example.com",
                 "Certificate" => "base64cert",
                 "CertificateKey" => "base64key"
               }

        {:ok, ""}
      end)

      assert {:ok, nil} =
               Bunnyx.PullZone.add_certificate(
                 client,
                 12_345,
                 "cdn.example.com",
                 "base64cert",
                 "base64key"
               )
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 400, message: "Bad request"}

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/pullzone/12345/addCertificate", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} =
               Bunnyx.PullZone.add_certificate(client, 12_345, "cdn.example.com", "c", "k")
    end
  end

  describe "remove_certificate/3" do
    test "sends hostname and returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :delete, "/pullzone/12345/removeCertificate", opts ->
        assert opts[:json] == %{"Hostname" => "cdn.example.com"}
        {:ok, ""}
      end)

      assert {:ok, nil} =
               Bunnyx.PullZone.remove_certificate(client, 12_345, "cdn.example.com")
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 400, message: "Bad request"}

      expect(Bunnyx.HTTP, :request, fn _req,
                                       :delete,
                                       "/pullzone/12345/removeCertificate",
                                       _opts ->
        {:error, error}
      end)

      assert {:error, ^error} =
               Bunnyx.PullZone.remove_certificate(client, 12_345, "cdn.example.com")
    end
  end

  describe "add_allowed_referrer/3" do
    test "sends hostname and returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :post, "/pullzone/12345/addAllowedReferrer", opts ->
        assert opts[:json] == %{"Hostname" => "example.com"}
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.PullZone.add_allowed_referrer(client, 12_345, "example.com")
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 400, message: "Bad request"}

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/pullzone/12345/addAllowedReferrer", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} =
               Bunnyx.PullZone.add_allowed_referrer(client, 12_345, "example.com")
    end
  end

  describe "remove_allowed_referrer/3" do
    test "sends hostname and returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req,
                                       :post,
                                       "/pullzone/12345/removeAllowedReferrer",
                                       opts ->
        assert opts[:json] == %{"Hostname" => "example.com"}
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.PullZone.remove_allowed_referrer(client, 12_345, "example.com")
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 400, message: "Bad request"}

      expect(Bunnyx.HTTP, :request, fn _req,
                                       :post,
                                       "/pullzone/12345/removeAllowedReferrer",
                                       _opts ->
        {:error, error}
      end)

      assert {:error, ^error} =
               Bunnyx.PullZone.remove_allowed_referrer(client, 12_345, "example.com")
    end
  end

  describe "add_blocked_referrer/3" do
    test "sends hostname and returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :post, "/pullzone/12345/addBlockedReferrer", opts ->
        assert opts[:json] == %{"Hostname" => "spam.com"}
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.PullZone.add_blocked_referrer(client, 12_345, "spam.com")
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 400, message: "Bad request"}

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/pullzone/12345/addBlockedReferrer", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} =
               Bunnyx.PullZone.add_blocked_referrer(client, 12_345, "spam.com")
    end
  end

  describe "remove_blocked_referrer/3" do
    test "sends hostname and returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req,
                                       :post,
                                       "/pullzone/12345/removeBlockedReferrer",
                                       opts ->
        assert opts[:json] == %{"Hostname" => "spam.com"}
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.PullZone.remove_blocked_referrer(client, 12_345, "spam.com")
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 400, message: "Bad request"}

      expect(Bunnyx.HTTP, :request, fn _req,
                                       :post,
                                       "/pullzone/12345/removeBlockedReferrer",
                                       _opts ->
        {:error, error}
      end)

      assert {:error, ^error} =
               Bunnyx.PullZone.remove_blocked_referrer(client, 12_345, "spam.com")
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
