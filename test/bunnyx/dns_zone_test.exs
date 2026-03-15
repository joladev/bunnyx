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
