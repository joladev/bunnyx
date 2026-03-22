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

  @derive {Inspect, except: [:password, :read_only_password]}
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
           [t()]
           | %{
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
      {:ok, body} when is_list(body) ->
        {:ok, Enum.map(body, &from_response/1)}

      {:ok, body} when is_map(body) ->
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

  @doc """
  Returns storage zone statistics.

  ## Options

    * `:date_from` — start date (ISO 8601 string)
    * `:date_to` — end date (ISO 8601 string)

  """
  @spec statistics(Bunnyx.t() | keyword(), pos_integer(), keyword()) ::
          {:ok, %{storage_used_chart: map(), file_count_chart: map()}}
          | {:error, Bunnyx.Error.t()}
  def statistics(client, id, opts \\ []) do
    client = Bunnyx.resolve(client)

    params =
      opts
      |> Keyword.take([:date_from, :date_to])
      |> to_statistics_params()

    case Bunnyx.HTTP.request(client.req, :get, "/storagezone/#{id}/statistics", params: params) do
      {:ok, body} ->
        {:ok,
         %{
           storage_used_chart: body["StorageUsedChart"],
           file_count_chart: body["FileCountChart"]
         }}

      {:error, _} = error ->
        error
    end
  end

  @doc "Resets the storage zone password."
  @spec reset_password(Bunnyx.t() | keyword(), pos_integer()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def reset_password(client, id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/storagezone/#{id}/resetPassword", []) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Resets the storage zone read-only password."
  @spec reset_read_only_password(Bunnyx.t() | keyword(), pos_integer()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def reset_read_only_password(client, id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/storagezone/resetReadOnlyPassword",
           params: %{"id" => id}
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Checks if a storage zone name is available."
  @spec check_availability(Bunnyx.t() | keyword(), String.t()) ::
          {:ok, boolean()} | {:error, Bunnyx.Error.t()}
  def check_availability(client, name) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/storagezone/checkavailability",
           json: %{"Name" => name}
         ) do
      {:ok, body} -> {:ok, body["Available"]}
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
    Bunnyx.Params.map_keys!(attrs, @reverse_mapping)
  end

  defp to_statistics_params(opts) do
    mapping = %{date_from: "dateFrom", date_to: "dateTo"}

    Map.new(opts, fn {key, value} ->
      {Map.fetch!(mapping, key), value}
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
