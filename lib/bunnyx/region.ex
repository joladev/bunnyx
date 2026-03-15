defmodule Bunnyx.Region do
  @moduledoc """
  Edge regions available on the bunny.net network. Useful for understanding
  pricing and geographic distribution.

  Uses the main API client created with `Bunnyx.new/1`.

  ## Usage

      client = Bunnyx.new(api_key: "sk-...")

      {:ok, regions} = Bunnyx.Region.list(client)
  """

  @field_mapping %{
    "Id" => :id,
    "Name" => :name,
    "PricePerGigabyte" => :price_per_gigabyte,
    "RegionCode" => :region_code,
    "ContinentCode" => :continent_code,
    "CountryCode" => :country_code,
    "Latitude" => :latitude,
    "Longitude" => :longitude,
    "AllowLatencyRouting" => :allow_latency_routing
  }

  @doc "Lists all available edge regions."
  @spec list(Bunnyx.t() | keyword()) :: {:ok, [map()]} | {:error, Bunnyx.Error.t()}
  def list(client) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/region", []) do
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
