defmodule Bunnyx.StorageZone do
  @moduledoc """
  Storage zones are the containers that hold files served through bunny.net's edge
  storage network. This module manages storage zones through the main API — creating,
  configuring, and deleting them.

  This is separate from `Bunnyx.Storage`, which handles file operations (upload,
  download) within a storage zone using a different authentication method.

  Uses the main API client created with `Bunnyx.new/1`.

  ## Usage

      client = Bunnyx.new(api_key: "sk-...")

      {:ok, zone} = Bunnyx.StorageZone.create(client,
        name: "my-zone",
        region: "DE"
      )

      {:ok, zone} = Bunnyx.StorageZone.get(client, zone.id)
      {:ok, page} = Bunnyx.StorageZone.list(client)
      {:ok, zone} = Bunnyx.StorageZone.update(client, zone.id, rewrite_404_to_200: true)
      {:ok, nil} = Bunnyx.StorageZone.delete(client, zone.id)
  """

  @type t :: %__MODULE__{
          id: pos_integer() | nil,
          name: String.t() | nil,
          password: String.t() | nil,
          read_only_password: String.t() | nil,
          date_modified: String.t() | nil,
          deleted: boolean() | nil,
          storage_used: integer() | nil,
          files_stored: integer() | nil,
          region: String.t() | nil,
          replication_regions: [String.t()] | nil,
          storage_hostname: String.t() | nil,
          rewrite_404_to_200: boolean() | nil,
          custom_404_file_path: String.t() | nil,
          zone_tier: integer() | nil
        }

  defstruct [
    :id,
    :name,
    :password,
    :read_only_password,
    :date_modified,
    :deleted,
    :storage_used,
    :files_stored,
    :region,
    :replication_regions,
    :storage_hostname,
    :rewrite_404_to_200,
    :custom_404_file_path,
    :zone_tier
  ]

  @field_mapping %{
    "Id" => :id,
    "Name" => :name,
    "Password" => :password,
    "ReadOnlyPassword" => :read_only_password,
    "DateModified" => :date_modified,
    "Deleted" => :deleted,
    "StorageUsed" => :storage_used,
    "FilesStored" => :files_stored,
    "Region" => :region,
    "ReplicationRegions" => :replication_regions,
    "StorageHostname" => :storage_hostname,
    "Rewrite404To200" => :rewrite_404_to_200,
    "Custom404FilePath" => :custom_404_file_path,
    "ZoneTier" => :zone_tier,
    # Write-only: update endpoint uses different names than the response
    "OriginUrl" => :origin_url,
    "ReplicationZones" => :replication_zones
  }

  @reverse_mapping Map.new(@field_mapping, fn {pascal, atom} -> {atom, pascal} end)

  @doc """
  Lists storage zones.

  ## Options

    * `:page` — page number
    * `:per_page` — items per page
    * `:search` — search term
    * `:include_deleted` — include deleted zones

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
      |> Keyword.take([:page, :per_page, :search, :include_deleted])
      |> to_query_params()

    case Bunnyx.HTTP.request(client.req, :get, "/storagezone", params: params) do
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

  @doc "Fetches a storage zone by ID."
  @spec get(Bunnyx.t() | keyword(), pos_integer()) :: {:ok, t()} | {:error, Bunnyx.Error.t()}
  def get(client, id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/storagezone/#{id}", []) do
      {:ok, body} -> {:ok, from_response(body)}
      {:error, _} = error -> error
    end
  end

  @doc "Creates a storage zone with the given attributes."
  @spec create(Bunnyx.t() | keyword(), keyword()) :: {:ok, t()} | {:error, Bunnyx.Error.t()}
  def create(client, attrs) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/storagezone", json: to_request_body(attrs)) do
      {:ok, body} -> {:ok, from_response(body)}
      {:error, _} = error -> error
    end
  end

  @doc "Updates a storage zone."
  @spec update(Bunnyx.t() | keyword(), pos_integer(), keyword()) ::
          {:ok, t()} | {:error, Bunnyx.Error.t()}
  def update(client, id, attrs) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/storagezone/#{id}",
           json: to_request_body(attrs)
         ) do
      {:ok, body} -> {:ok, from_response(body)}
      {:error, _} = error -> error
    end
  end

  @doc "Deletes a storage zone."
  @spec delete(Bunnyx.t() | keyword(), pos_integer()) :: {:ok, nil} | {:error, Bunnyx.Error.t()}
  def delete(client, id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :delete, "/storagezone/#{id}", []) do
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
    mapping = %{
      page: "page",
      per_page: "perPage",
      search: "search",
      include_deleted: "includeDeleted"
    }

    Map.new(opts, fn {key, value} ->
      {Map.fetch!(mapping, key), value}
    end)
  end
end
