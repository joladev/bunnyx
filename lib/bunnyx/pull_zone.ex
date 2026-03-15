defmodule Bunnyx.PullZone do
  @moduledoc """
  Pull zones are bunny.net's CDN distribution points. Each pull zone pulls content
  from your origin server and caches it across their global edge network.

  Uses the main API client created with `Bunnyx.new/1`.

  ## Usage

      client = Bunnyx.new(api_key: "sk-...")

      {:ok, zone} = Bunnyx.PullZone.create(client,
        name: "my-zone",
        origin_url: "https://example.com"
      )

      {:ok, zone} = Bunnyx.PullZone.get(client, zone.id)
      {:ok, page} = Bunnyx.PullZone.list(client)
      {:ok, zone} = Bunnyx.PullZone.update(client, zone.id, cache_control_max_age_override: 3600)
      {:ok, nil} = Bunnyx.PullZone.delete(client, zone.id)
  """

  @type t :: %__MODULE__{
          id: pos_integer() | nil,
          name: String.t() | nil,
          origin_url: String.t() | nil,
          enabled: boolean() | nil,
          suspended: boolean() | nil,
          hostnames: [map()] | nil,
          storage_zone_id: integer() | nil,
          monthly_bandwidth_limit: integer() | nil,
          monthly_bandwidth_used: integer() | nil,
          cache_control_max_age_override: integer() | nil,
          ignore_query_strings: boolean() | nil,
          type: integer() | nil
        }

  defstruct [
    :id,
    :name,
    :origin_url,
    :enabled,
    :suspended,
    :hostnames,
    :storage_zone_id,
    :monthly_bandwidth_limit,
    :monthly_bandwidth_used,
    :cache_control_max_age_override,
    :ignore_query_strings,
    :type
  ]

  @field_mapping %{
    "Id" => :id,
    "Name" => :name,
    "OriginUrl" => :origin_url,
    "Enabled" => :enabled,
    "Suspended" => :suspended,
    "Hostnames" => :hostnames,
    "StorageZoneId" => :storage_zone_id,
    "MonthlyBandwidthLimit" => :monthly_bandwidth_limit,
    "MonthlyBandwidthUsed" => :monthly_bandwidth_used,
    "CacheControlMaxAgeOverride" => :cache_control_max_age_override,
    "IgnoreQueryStrings" => :ignore_query_strings,
    "Type" => :type
  }

  @reverse_mapping Map.new(@field_mapping, fn {pascal, atom} -> {atom, pascal} end)

  @doc """
  Lists pull zones.

  ## Options

    * `:page` — page number
    * `:per_page` — items per page
    * `:search` — search term

  """
  @spec list(Bunnyx.t() | keyword(), keyword()) ::
          {:ok,
           %{
             items: [t()],
             current_page: integer(),
             total_items: integer(),
             has_more_items: boolean()
           }}
          | {:error, Bunnyx.Error.t()}
  def list(client, opts \\ []) do
    client = Bunnyx.resolve(client)

    params =
      opts
      |> Keyword.take([:page, :per_page, :search])
      |> to_query_params()

    case Bunnyx.HTTP.request(client.req, :get, "/pullzone", params: params) do
      {:ok, body} ->
        {:ok,
         %{
           items: Enum.map(body["Items"], &from_response/1),
           current_page: body["CurrentPage"],
           total_items: body["TotalItems"],
           has_more_items: body["HasMoreItems"]
         }}

      {:error, _} = error ->
        error
    end
  end

  @doc "Fetches a pull zone by ID."
  @spec get(Bunnyx.t() | keyword(), pos_integer()) :: {:ok, t()} | {:error, Bunnyx.Error.t()}
  def get(client, id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/pullzone/#{id}", []) do
      {:ok, body} -> {:ok, from_response(body)}
      {:error, _} = error -> error
    end
  end

  @doc "Creates a pull zone with the given attributes."
  @spec create(Bunnyx.t() | keyword(), keyword()) :: {:ok, t()} | {:error, Bunnyx.Error.t()}
  def create(client, attrs) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/pullzone", json: to_request_body(attrs)) do
      {:ok, body} -> {:ok, from_response(body)}
      {:error, _} = error -> error
    end
  end

  @doc "Updates a pull zone."
  @spec update(Bunnyx.t() | keyword(), pos_integer(), keyword()) ::
          {:ok, t()} | {:error, Bunnyx.Error.t()}
  def update(client, id, attrs) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/pullzone/#{id}", json: to_request_body(attrs)) do
      {:ok, body} -> {:ok, from_response(body)}
      {:error, _} = error -> error
    end
  end

  @doc "Deletes a pull zone."
  @spec delete(Bunnyx.t() | keyword(), pos_integer()) :: {:ok, nil} | {:error, Bunnyx.Error.t()}
  def delete(client, id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :delete, "/pullzone/#{id}", []) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Adds a custom hostname to a pull zone."
  @spec add_hostname(Bunnyx.t() | keyword(), pos_integer(), String.t()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def add_hostname(client, id, hostname) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/pullzone/#{id}/addHostname",
           json: %{"Hostname" => hostname}
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Removes a custom hostname from a pull zone."
  @spec remove_hostname(Bunnyx.t() | keyword(), pos_integer(), String.t()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def remove_hostname(client, id, hostname) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :delete, "/pullzone/#{id}/removeHostname",
           json: %{"Hostname" => hostname}
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Adds an IP address to the pull zone's block list."
  @spec add_blocked_ip(Bunnyx.t() | keyword(), pos_integer(), String.t()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def add_blocked_ip(client, id, ip) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/pullzone/#{id}/addBlockedIp",
           json: %{"Value" => ip}
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Removes an IP address from the pull zone's block list."
  @spec remove_blocked_ip(Bunnyx.t() | keyword(), pos_integer(), String.t()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def remove_blocked_ip(client, id, ip) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/pullzone/#{id}/removeBlockedIp",
           json: %{"Value" => ip}
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Resets the token authentication security key for a pull zone."
  @spec reset_security_key(Bunnyx.t() | keyword(), pos_integer()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def reset_security_key(client, id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/pullzone/#{id}/resetSecurityKey", []) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Checks if a pull zone name is available."
  @spec check_availability(Bunnyx.t() | keyword(), String.t()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def check_availability(client, name) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/pullzone/checkavailability",
           json: %{"Name" => name}
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  defp from_response(data) when is_map(data) do
    fields =
      for {pascal, atom} <- @field_mapping, Map.has_key?(data, pascal), into: %{} do
        {atom, data[pascal]}
      end

    struct(__MODULE__, fields)
  end

  defp to_request_body(attrs) do
    Map.new(attrs, fn {key, value} ->
      pascal = Map.fetch!(@reverse_mapping, key)
      {pascal, value}
    end)
  end

  defp to_query_params(opts) do
    mapping = %{page: "page", per_page: "perPage", search: "search"}

    Map.new(opts, fn {key, value} ->
      {Map.fetch!(mapping, key), value}
    end)
  end
end
