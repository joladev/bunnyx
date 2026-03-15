defmodule Bunnyx.Country do
  @moduledoc """
  Countries and their associated tax rates. Useful for configuring geo-blocking
  on pull zones.

  Uses the main API client created with `Bunnyx.new/1`.

  ## Usage

      client = Bunnyx.new(api_key: "sk-...")

      {:ok, countries} = Bunnyx.Country.list(client)
  """

  @field_mapping %{
    "Name" => :name,
    "IsoCode" => :iso_code,
    "IsEU" => :is_eu,
    "TaxRate" => :tax_rate,
    "TaxPrefix" => :tax_prefix,
    "FlagUrl" => :flag_url,
    "PopList" => :pop_list
  }

  @doc "Lists all countries."
  @spec list(Bunnyx.t() | keyword()) :: {:ok, [map()]} | {:error, Bunnyx.Error.t()}
  def list(client) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/country", []) do
      {:ok, body} -> {:ok, Enum.map(body, &from_response/1)}
      {:error, _} = error -> error
    end
  end

  defp from_response(data) when is_map(data) do
    for {pascal, atom} <- @field_mapping, Map.has_key?(data, pascal), into: %{} do
      {atom, data[pascal]}
    end
  end
end
