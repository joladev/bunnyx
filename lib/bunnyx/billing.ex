defmodule Bunnyx.Billing do
  @moduledoc """
  Account billing details and per-zone usage summaries.

  Uses the main API client created with `Bunnyx.new/1`.

  ## Usage

      client = Bunnyx.new(api_key: "sk-...")

      {:ok, billing} = Bunnyx.Billing.details(client)
      {:ok, summary} = Bunnyx.Billing.summary(client)
  """

  @details_mapping %{
    "Balance" => :balance,
    "ThisMonthCharges" => :this_month_charges,
    "BillingEnabled" => :billing_enabled,
    "MonthlyBandwidthUsed" => :monthly_bandwidth_used,
    "MonthlyChargesStorage" => :monthly_charges_storage,
    "MonthlyChargesDNS" => :monthly_charges_dns,
    "MonthlyChargesOptimizer" => :monthly_charges_optimizer,
    "MonthlyChargesEUTraffic" => :monthly_charges_eu_traffic,
    "MonthlyChargesUSTraffic" => :monthly_charges_us_traffic,
    "MonthlyChargesASIATraffic" => :monthly_charges_asia_traffic,
    "MonthlyChargesAFTraffic" => :monthly_charges_af_traffic,
    "MonthlyChargesSATraffic" => :monthly_charges_sa_traffic,
    "MonthlyChargesTranscribe" => :monthly_charges_transcribe,
    "MonthlyChargesPremiumEncoding" => :monthly_charges_premium_encoding,
    "MonthlyChargesDrm" => :monthly_charges_drm,
    "MonthlyChargesShield" => :monthly_charges_shield,
    "MonthlyChargesTaxes" => :monthly_charges_taxes,
    "MonthlyChargesScripting" => :monthly_charges_scripting,
    "MonthlyChargesMagicContainers" => :monthly_charges_magic_containers
  }

  @doc "Returns account billing details including balance, charges, and usage."
  @spec details(Bunnyx.t() | keyword()) :: {:ok, map()} | {:error, Bunnyx.Error.t()}
  def details(client) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/billing", []) do
      {:ok, body} ->
        {:ok, from_details_response(body)}

      {:error, _} = error ->
        error
    end
  end

  @doc "Returns a per-pull-zone usage summary for the current month."
  @spec summary(Bunnyx.t() | keyword()) :: {:ok, [map()]} | {:error, Bunnyx.Error.t()}
  def summary(client) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/billing/summary", []) do
      {:ok, body} ->
        {:ok, Enum.map(body, &from_summary_item/1)}

      {:error, _} = error ->
        error
    end
  end

  defp from_details_response(data) when is_map(data) do
    for {pascal, atom} <- @details_mapping, Map.has_key?(data, pascal), into: %{} do
      {atom, data[pascal]}
    end
  end

  defp from_summary_item(data) when is_map(data) do
    %{
      pull_zone_id: data["PullZoneId"],
      monthly_usage: data["MonthlyUsage"],
      monthly_bandwidth_used: data["MonthlyBandwidthUsed"]
    }
  end
end
