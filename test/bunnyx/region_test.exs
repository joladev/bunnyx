defmodule Bunnyx.RegionTest do
  use ExUnit.Case, async: true
  use Mimic

  setup do
    %{client: Bunnyx.new(api_key: "sk-test")}
  end

  describe "list/1" do
    test "returns parsed regions", %{client: client} do
      response = [
        %{
          "Id" => 1,
          "Name" => "Europe (Frankfurt)",
          "PricePerGigabyte" => 0.01,
          "RegionCode" => "DE",
          "ContinentCode" => "EU",
          "CountryCode" => "DE",
          "Latitude" => 50.1109,
          "Longitude" => 8.6821,
          "AllowLatencyRouting" => true
        }
      ]

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/region", _opts ->
        {:ok, response}
      end)

      assert {:ok, [region]} = Bunnyx.Region.list(client)
      assert region.id == 1
      assert region.name == "Europe (Frankfurt)"
      assert region.region_code == "DE"
      assert region.allow_latency_routing == true
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 500, message: "Server error"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/region", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.Region.list(client)
    end
  end
end
