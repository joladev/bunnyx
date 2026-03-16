defmodule Bunnyx.BillingTest do
  use ExUnit.Case, async: true
  use Mimic

  setup do
    %{client: Bunnyx.new(api_key: "sk-test")}
  end

  describe "details/1" do
    test "returns parsed billing details", %{client: client} do
      response = %{
        "Balance" => 25.50,
        "ThisMonthCharges" => 12.30,
        "BillingEnabled" => true,
        "MonthlyBandwidthUsed" => 1_073_741_824,
        "MonthlyChargesStorage" => 1.50,
        "MonthlyChargesDNS" => 0.0,
        "MonthlyChargesEUTraffic" => 5.00,
        "MonthlyChargesUSTraffic" => 3.00
      }

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/billing", _opts ->
        {:ok, response}
      end)

      assert {:ok, billing} = Bunnyx.Billing.details(client)
      assert billing.balance == 25.50
      assert billing.this_month_charges == 12.30
      assert billing.billing_enabled == true
      assert billing.monthly_charges_storage == 1.50
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 401, message: "Unauthorized"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/billing", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.Billing.details(client)
    end
  end

  describe "summary/1" do
    test "returns per-zone usage summary", %{client: client} do
      response = [
        %{
          "PullZoneId" => 12_345,
          "MonthlyUsage" => 5.25,
          "MonthlyBandwidthUsed" => 536_870_912
        }
      ]

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/billing/summary", _opts ->
        {:ok, response}
      end)

      assert {:ok, [item]} = Bunnyx.Billing.summary(client)
      assert item.pull_zone_id == 12_345
      assert item.monthly_usage == 5.25
      assert item.monthly_bandwidth_used == 536_870_912
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 500, message: "Server error"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/billing/summary", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.Billing.summary(client)
    end
  end
end
