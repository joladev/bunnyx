defmodule Bunnyx.DnsZoneTest do
  use ExUnit.Case, async: true
  use Mimic

  setup do
    %{client: Bunnyx.new(api_key: "sk-test")}
  end

  describe "list/2" do
    test "returns parsed dns zones", %{client: client} do
      response = Bunnyx.Factory.dns_zone_list_response()

      expect(Bunnyx.HTTP, :request, fn req, :get, "/dnszone", opts ->
        assert req == client.req
        assert opts[:params] == %{}
        {:ok, response}
      end)

      assert {:ok, page} = Bunnyx.DnsZone.list(client)
      assert [%Bunnyx.DnsZone{id: 50_001, domain: "example.com"}] = page.items
      assert page.current_page == 1
      assert page.total_items == 1
      assert page.has_more_items == false
    end

    test "passes query params", %{client: client} do
      response = Bunnyx.Factory.dns_zone_list_response()

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/dnszone", opts ->
        assert opts[:params] == %{"page" => 2, "perPage" => 10, "search" => "example"}
        {:ok, response}
      end)

      Bunnyx.DnsZone.list(client, page: 2, per_page: 10, search: "example")
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 500, message: "Server error"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/dnszone", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.DnsZone.list(client)
    end
  end

  describe "get/2" do
    test "returns parsed zone with nested records", %{client: client} do
      response = Bunnyx.Factory.dns_zone_response()

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/dnszone/50001", _opts ->
        {:ok, response}
      end)

      assert {:ok, %Bunnyx.DnsZone{id: 50_001, domain: "example.com", records: records}} =
               Bunnyx.DnsZone.get(client, 50_001)

      assert [%Bunnyx.DnsRecord{id: 99_001, name: "www", value: "1.2.3.4"}] = records
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 404, message: "Not found"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/dnszone/999", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.DnsZone.get(client, 999)
    end
  end

  describe "create/2" do
    test "sends attrs and returns parsed zone", %{client: client} do
      response = Bunnyx.Factory.dns_zone_response()

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/dnszone", opts ->
        assert opts[:json] == %{"Domain" => "example.com"}
        {:ok, response}
      end)

      assert {:ok, %Bunnyx.DnsZone{domain: "example.com"}} =
               Bunnyx.DnsZone.create(client, domain: "example.com")
    end
  end

  describe "update/3" do
    test "sends attrs to correct path", %{client: client} do
      response = Bunnyx.Factory.dns_zone_response(%{"LoggingEnabled" => true})

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/dnszone/50001", opts ->
        assert opts[:json] == %{"LoggingEnabled" => true}
        {:ok, response}
      end)

      assert {:ok, %Bunnyx.DnsZone{logging_enabled: true}} =
               Bunnyx.DnsZone.update(client, 50_001, logging_enabled: true)
    end
  end

  describe "delete/2" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :delete, "/dnszone/50001", _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.DnsZone.delete(client, 50_001)
    end
  end

  describe "enable_dnssec/2" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :post, "/dnszone/50001/dnssec", _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.DnsZone.enable_dnssec(client, 50_001)
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 500, message: "Server error"}

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/dnszone/50001/dnssec", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.DnsZone.enable_dnssec(client, 50_001)
    end
  end

  describe "disable_dnssec/2" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :delete, "/dnszone/50001/dnssec", _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.DnsZone.disable_dnssec(client, 50_001)
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 500, message: "Server error"}

      expect(Bunnyx.HTTP, :request, fn _req, :delete, "/dnszone/50001/dnssec", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.DnsZone.disable_dnssec(client, 50_001)
    end
  end

  describe "export/2" do
    test "returns zone file text", %{client: client} do
      zone_file = "example.com. 3600 IN A 1.2.3.4\n"

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/dnszone/50001/export", _opts ->
        {:ok, zone_file}
      end)

      assert {:ok, ^zone_file} = Bunnyx.DnsZone.export(client, 50_001)
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 404, message: "Not found"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/dnszone/50001/export", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.DnsZone.export(client, 50_001)
    end
  end

  describe "import_records/3" do
    test "sends zone data and returns result summary", %{client: client} do
      zone_data = "example.com. 3600 IN A 1.2.3.4\n"

      response = %{
        "RecordsSuccessful" => 5,
        "RecordsFailed" => 1,
        "RecordsSkipped" => 2
      }

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/dnszone/50001/import", opts ->
        assert opts[:body] == zone_data
        {:ok, response}
      end)

      assert {:ok, result} = Bunnyx.DnsZone.import_records(client, 50_001, zone_data)
      assert result.records_successful == 5
      assert result.records_failed == 1
      assert result.records_skipped == 2
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 400, message: "Bad request"}

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/dnszone/50001/import", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.DnsZone.import_records(client, 50_001, "invalid")
    end
  end

  describe "statistics/3" do
    test "returns parsed statistics", %{client: client} do
      response = %{
        "TotalQueriesServed" => 1000,
        "QueriesServedChart" => %{"2025-06-01" => 500, "2025-06-02" => 500},
        "NormalQueriesServedChart" => %{"2025-06-01" => 400, "2025-06-02" => 400},
        "SmartQueriesServedChart" => %{"2025-06-01" => 100, "2025-06-02" => 100},
        "QueriesByTypeChart" => %{"1" => 800, "28" => 200}
      }

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/dnszone/50001/statistics", opts ->
        assert opts[:params] == %{}
        {:ok, response}
      end)

      assert {:ok, stats} = Bunnyx.DnsZone.statistics(client, 50_001)
      assert stats.total_queries_served == 1000
      assert stats.queries_served_chart == %{"2025-06-01" => 500, "2025-06-02" => 500}
      assert stats.queries_by_type_chart == %{"1" => 800, "28" => 200}
    end

    test "passes date params", %{client: client} do
      response = %{
        "TotalQueriesServed" => 0,
        "QueriesServedChart" => %{},
        "NormalQueriesServedChart" => %{},
        "SmartQueriesServedChart" => %{},
        "QueriesByTypeChart" => %{}
      }

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/dnszone/50001/statistics", opts ->
        assert opts[:params] == %{"dateFrom" => "2025-06-01", "dateTo" => "2025-06-30"}
        {:ok, response}
      end)

      Bunnyx.DnsZone.statistics(client, 50_001,
        date_from: "2025-06-01",
        date_to: "2025-06-30"
      )
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 500, message: "Server error"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/dnszone/50001/statistics", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.DnsZone.statistics(client, 50_001)
    end
  end

  describe "check_availability/2" do
    test "returns {:ok, nil} when available", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :post, "/dnszone/checkavailability", opts ->
        assert opts[:json] == %{"Name" => "example.com"}
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.DnsZone.check_availability(client, "example.com")
    end

    test "returns error when unavailable", %{client: client} do
      error = %Bunnyx.Error{status: 400, message: "Name already taken"}

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/dnszone/checkavailability", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.DnsZone.check_availability(client, "taken.com")
    end
  end

  describe "issue_certificate/2" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :post, "/dnszone/50001/certificate/issue", _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.DnsZone.issue_certificate(client, 50_001)
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 400, message: "Failed to issue certificate"}

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/dnszone/50001/certificate/issue", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.DnsZone.issue_certificate(client, 50_001)
    end
  end

  describe "resolve" do
    test "accepts keyword list as client" do
      response = Bunnyx.Factory.dns_zone_response()

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/dnszone/1", _opts ->
        {:ok, response}
      end)

      assert {:ok, %Bunnyx.DnsZone{}} = Bunnyx.DnsZone.get([api_key: "sk-test"], 1)
    end
  end
end
