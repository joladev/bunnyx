defmodule Bunnyx.Shield do
  @moduledoc """
  Bunny Shield — WAF, rate limiting, bot detection, and access control for
  pull zones. A Shield zone wraps a pull zone with security configuration.

  Uses the main API client created with `Bunnyx.new/1`. The Shield API lives
  under `/shield/...` on the same base URL.

  ## Usage

      client = Bunnyx.new(api_key: "sk-...")

      {:ok, zone} = Bunnyx.Shield.create(client, 12345)
      {:ok, zones} = Bunnyx.Shield.list(client)
      {:ok, zone} = Bunnyx.Shield.get(client, zone.shield_zone_id)
      {:ok, zone} = Bunnyx.Shield.get_by_pull_zone(client, 12345)
      {:ok, zone} = Bunnyx.Shield.update(client, zone.shield_zone_id, waf_enabled: true)
  """

  alias Bunnyx.Shield.Zone

  @doc "Creates a Shield zone for a pull zone."
  @spec create(Bunnyx.t() | keyword(), pos_integer(), keyword()) ::
          {:ok, Zone.t()} | {:error, Bunnyx.Error.t()}
  def create(client, pull_zone_id, opts \\ []) do
    client = Bunnyx.resolve(client)

    json = %{"pullZoneId" => pull_zone_id}

    json =
      if opts != [] do
        Map.put(json, "shieldZone", Zone.to_request_body(opts))
      else
        json
      end

    case Bunnyx.HTTP.request(client.req, :post, "/shield/shield-zone", json: json) do
      {:ok, body} -> {:ok, unwrap_data(body)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Lists all Shield zones.

  ## Options

    * `:page` — page number
    * `:page_size` — items per page

  """
  @spec list(Bunnyx.t() | keyword(), keyword()) ::
          {:ok, %{items: [Zone.t()], page: map()}} | {:error, Bunnyx.Error.t()}
  def list(client, opts \\ []) do
    client = Bunnyx.resolve(client)
    params = to_page_params(opts)

    case Bunnyx.HTTP.request(client.req, :get, "/shield/shield-zones", params: params) do
      {:ok, body} ->
        {:ok, unwrap_list(body)}

      {:error, _} = error ->
        error
    end
  end

  @doc "Lists active Shield zones with pull zone mapping."
  @spec list_active(Bunnyx.t() | keyword(), keyword()) ::
          {:ok, %{items: [Zone.t()], page: map()}} | {:error, Bunnyx.Error.t()}
  def list_active(client, opts \\ []) do
    client = Bunnyx.resolve(client)
    params = to_page_params(opts)

    case Bunnyx.HTTP.request(client.req, :get, "/shield/shield-zones/active", params: params) do
      {:ok, body} ->
        {:ok, unwrap_list(body)}

      {:error, _} = error ->
        error
    end
  end

  @doc "Fetches a Shield zone by ID."
  @spec get(Bunnyx.t() | keyword(), pos_integer()) ::
          {:ok, Zone.t()} | {:error, Bunnyx.Error.t()}
  def get(client, shield_zone_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/shield/shield-zone/#{shield_zone_id}", []) do
      {:ok, body} -> {:ok, unwrap_data(body)}
      {:error, _} = error -> error
    end
  end

  @doc "Fetches a Shield zone by its associated pull zone ID."
  @spec get_by_pull_zone(Bunnyx.t() | keyword(), pos_integer()) ::
          {:ok, Zone.t()} | {:error, Bunnyx.Error.t()}
  def get_by_pull_zone(client, pull_zone_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(
           client.req,
           :get,
           "/shield/shield-zone/pull-zone/#{pull_zone_id}",
           []
         ) do
      {:ok, body} -> {:ok, unwrap_data(body)}
      {:error, _} = error -> error
    end
  end

  @doc "Updates a Shield zone's configuration."
  @spec update(Bunnyx.t() | keyword(), pos_integer(), keyword()) ::
          {:ok, Zone.t()} | {:error, Bunnyx.Error.t()}
  def update(client, shield_zone_id, attrs) do
    client = Bunnyx.resolve(client)

    json = %{
      "shieldZoneId" => shield_zone_id,
      "shieldZone" => Zone.to_request_body(attrs)
    }

    case Bunnyx.HTTP.request(client.req, :patch, "/shield/shield-zone", json: json) do
      {:ok, body} -> {:ok, unwrap_data(body)}
      {:error, _} = error -> error
    end
  end

  defp unwrap_data(%{"data" => data}) when is_map(data), do: Zone.from_response(data)
  defp unwrap_data(body) when is_map(body), do: Zone.from_response(body)

  defp unwrap_list(body) do
    items =
      body
      |> Map.get("data", [])
      |> Enum.map(&Zone.from_response/1)

    %{items: items, page: body["page"]}
  end

  defp to_page_params(opts) do
    mapping = %{page: "page", page_size: "pageSize"}

    opts
    |> Keyword.take([:page, :page_size])
    |> Map.new(fn {key, value} ->
      {Map.fetch!(mapping, key), value}
    end)
  end
end
