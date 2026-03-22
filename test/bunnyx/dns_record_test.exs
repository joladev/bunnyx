defmodule Bunnyx.DnsRecordTest do
  use ExUnit.Case, async: true
  use Mimic

  setup do
    %{client: Bunnyx.new(api_key: "sk-test")}
  end

  describe "add/3" do
    test "sends PUT with JSON body and returns parsed record", %{client: client} do
      response = Bunnyx.Factory.dns_record_response()

      expect(Bunnyx.HTTP, :request, fn req, :put, "/dnszone/50001/records", opts ->
        assert req == client.req
        assert opts[:json] == %{"Type" => 0, "Name" => "www", "Value" => "1.2.3.4", "Ttl" => 300}
        {:ok, response}
      end)

      assert {:ok, %Bunnyx.DnsRecord{id: 99_001, name: "www", value: "1.2.3.4"}} =
               Bunnyx.DnsRecord.add(client, 50_001,
                 type: 0,
                 name: "www",
                 value: "1.2.3.4",
                 ttl: 300
               )
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 400, message: "Bad request"}

      expect(Bunnyx.HTTP, :request, fn _req, :put, "/dnszone/50001/records", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} =
               Bunnyx.DnsRecord.add(client, 50_001,
                 type: 0,
                 name: "www",
                 value: "1.2.3.4",
                 ttl: 300
               )
    end
  end

  describe "update/4" do
    test "sends POST with JSON body and returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :post, "/dnszone/50001/records/99001", opts ->
        assert opts[:json] == %{"Ttl" => 600}
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.DnsRecord.update(client, 50_001, 99_001, ttl: 600)
    end
  end

  describe "delete/3" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :delete, "/dnszone/50001/records/99001", _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.DnsRecord.delete(client, 50_001, 99_001)
    end
  end

  describe "resolve" do
    test "accepts keyword list as client" do
      response = Bunnyx.Factory.dns_record_response()

      expect(Bunnyx.HTTP, :request, fn _req, :put, "/dnszone/1/records", _opts ->
        {:ok, response}
      end)

      assert {:ok, %Bunnyx.DnsRecord{}} =
               Bunnyx.DnsRecord.add([api_key: "sk-test"], 1,
                 type: 0,
                 name: "www",
                 value: "1.2.3.4",
                 ttl: 300
               )
    end
  end
end
