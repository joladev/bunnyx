defmodule Bunnyx.PullZone do
  @moduledoc """
  Pull Zone API.

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

  @spec get(Bunnyx.t() | keyword(), pos_integer()) :: {:ok, t()} | {:error, Bunnyx.Error.t()}
  def get(client, id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/pullzone/#{id}", []) do
      {:ok, body} -> {:ok, from_response(body)}
      {:error, _} = error -> error
    end
  end

  @spec create(Bunnyx.t() | keyword(), keyword()) :: {:ok, t()} | {:error, Bunnyx.Error.t()}
  def create(client, attrs) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/pullzone", json: to_request_body(attrs)) do
      {:ok, body} -> {:ok, from_response(body)}
      {:error, _} = error -> error
    end
  end

  @spec update(Bunnyx.t() | keyword(), pos_integer(), keyword()) ::
          {:ok, t()} | {:error, Bunnyx.Error.t()}
  def update(client, id, attrs) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/pullzone/#{id}", json: to_request_body(attrs)) do
      {:ok, body} -> {:ok, from_response(body)}
      {:error, _} = error -> error
    end
  end

  @spec delete(Bunnyx.t() | keyword(), pos_integer()) :: {:ok, nil} | {:error, Bunnyx.Error.t()}
  def delete(client, id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :delete, "/pullzone/#{id}", []) do
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
