defmodule Bunnyx.ShieldTest do
  use ExUnit.Case, async: true
  use Mimic

  setup do
    %{client: Bunnyx.new(api_key: "sk-test")}
  end

  describe "create/3" do
    test "sends pull zone ID and returns parsed zone", %{client: client} do
      response = Bunnyx.Factory.shield_zone_wrapped_response()

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/shield/shield-zone", opts ->
        assert opts[:json] == %{"pullZoneId" => 12_345}
        {:ok, response}
      end)

      assert {:ok, %Bunnyx.Shield.Zone{shield_zone_id: 100_001, pull_zone_id: 12_345}} =
               Bunnyx.Shield.create(client, 12_345)
    end

    test "passes shield zone options", %{client: client} do
      response = Bunnyx.Factory.shield_zone_wrapped_response(%{"wafEnabled" => true})

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/shield/shield-zone", opts ->
        assert opts[:json]["pullZoneId"] == 12_345
        assert opts[:json]["shieldZone"]["wafEnabled"] == true
        {:ok, response}
      end)

      assert {:ok, %Bunnyx.Shield.Zone{}} =
               Bunnyx.Shield.create(client, 12_345, waf_enabled: true)
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 400, message: "Bad request"}

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/shield/shield-zone", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.Shield.create(client, 12_345)
    end
  end

  describe "list/2" do
    test "returns parsed shield zones", %{client: client} do
      response = Bunnyx.Factory.shield_zone_list_response()

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/shield/shield-zones", opts ->
        assert opts[:params] == %{}
        {:ok, response}
      end)

      assert {:ok, result} = Bunnyx.Shield.list(client)
      assert [%Bunnyx.Shield.Zone{shield_zone_id: 100_001}] = result.items
      assert result.page["totalCount"] == 1
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 500, message: "Server error"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/shield/shield-zones", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.Shield.list(client)
    end
  end

  describe "list_active/2" do
    test "returns active shield zones", %{client: client} do
      response = Bunnyx.Factory.shield_zone_list_response()

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/shield/shield-zones/active", _opts ->
        {:ok, response}
      end)

      assert {:ok, result} = Bunnyx.Shield.list_active(client)
      assert [%Bunnyx.Shield.Zone{}] = result.items
    end
  end

  describe "get/2" do
    test "returns parsed shield zone", %{client: client} do
      response = Bunnyx.Factory.shield_zone_wrapped_response()

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/shield/shield-zone/100001", _opts ->
        {:ok, response}
      end)

      assert {:ok, %Bunnyx.Shield.Zone{shield_zone_id: 100_001, waf_enabled: true}} =
               Bunnyx.Shield.get(client, 100_001)
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 404, message: "Not found"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/shield/shield-zone/999", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.Shield.get(client, 999)
    end
  end

  describe "get_by_pull_zone/2" do
    test "returns shield zone for pull zone", %{client: client} do
      response = Bunnyx.Factory.shield_zone_wrapped_response()

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/shield/shield-zone/pull-zone/12345", _opts ->
        {:ok, response}
      end)

      assert {:ok, %Bunnyx.Shield.Zone{pull_zone_id: 12_345}} =
               Bunnyx.Shield.get_by_pull_zone(client, 12_345)
    end
  end

  describe "update/3" do
    test "sends attrs via PATCH and returns parsed zone", %{client: client} do
      response = Bunnyx.Factory.shield_zone_wrapped_response(%{"wafEnabled" => false})

      expect(Bunnyx.HTTP, :request, fn _req, :patch, "/shield/shield-zone", opts ->
        assert opts[:json]["shieldZoneId"] == 100_001
        assert opts[:json]["shieldZone"]["wafEnabled"] == false
        {:ok, response}
      end)

      assert {:ok, %Bunnyx.Shield.Zone{}} =
               Bunnyx.Shield.update(client, 100_001, waf_enabled: false)
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 400, message: "Bad request"}

      expect(Bunnyx.HTTP, :request, fn _req, :patch, "/shield/shield-zone", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.Shield.update(client, 100_001, waf_enabled: true)
    end
  end
end
