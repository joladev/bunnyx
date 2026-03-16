defmodule Bunnyx.Stream do
  @moduledoc """
  Stream video management. Upload, manage, and deliver videos through bunny.net's
  Stream platform.

  Stream uses a **separate client** from the main API because it has its own
  authentication (a library-specific API key) and a different base URL.
  Create one with `Bunnyx.Stream.new/1`.

  ## Usage

      client = Bunnyx.Stream.new(api_key: "lib-api-key-...", library_id: 12345)

      {:ok, video} = Bunnyx.Stream.create(client, title: "My Video")
      {:ok, nil} = Bunnyx.Stream.upload(client, video.guid, video_binary)
      {:ok, video} = Bunnyx.Stream.get(client, video.guid)
      {:ok, page} = Bunnyx.Stream.list(client)
      {:ok, nil} = Bunnyx.Stream.delete(client, video.guid)
  """

  alias Bunnyx.Stream.Video

  @type t :: %__MODULE__{req: Req.Request.t(), library_id: pos_integer()}

  @enforce_keys [:req, :library_id]
  defstruct [:req, :library_id]

  @doc """
  Creates a new Stream client.

  ## Options

    * `:api_key` (required) — video library API key
    * `:library_id` (required) — video library ID
    * `:receive_timeout` — socket receive timeout in milliseconds (default `15_000`)
    * `:finch` — a custom Finch pool name

  """
  @spec new(keyword()) :: t()
  def new(opts) do
    api_key = Keyword.fetch!(opts, :api_key)
    library_id = Keyword.fetch!(opts, :library_id)

    req_opts =
      [base_url: "https://video.bunnycdn.com", headers: [{"AccessKey", api_key}]]
      |> maybe_put(:receive_timeout, opts[:receive_timeout])
      |> maybe_put(:finch, opts[:finch])

    %__MODULE__{req: Req.new(req_opts), library_id: library_id}
  end

  @doc false
  @spec resolve(t() | keyword()) :: t()
  def resolve(%__MODULE__{} = client), do: client
  def resolve(opts) when is_list(opts), do: new(opts)

  @doc """
  Lists videos in the library.

  ## Options

    * `:page` — page number
    * `:items_per_page` — items per page
    * `:search` — search term
    * `:collection` — filter by collection ID
    * `:order_by` — sort field (default `"date"`)

  """
  @spec list(t() | keyword(), keyword()) ::
          {:ok,
           %{
             items: [Video.t()],
             current_page: integer(),
             total_items: integer(),
             items_per_page: integer()
           }}
          | {:error, Bunnyx.Error.t()}
  def list(client, opts \\ []) do
    client = resolve(client)
    params = to_query_params(opts)

    case Bunnyx.HTTP.request(client.req, :get, "/library/#{client.library_id}/videos",
           params: params
         ) do
      {:ok, body} ->
        {:ok,
         %{
           items: Enum.map(body["items"], &Video.from_response/1),
           current_page: body["currentPage"],
           total_items: body["totalItems"],
           items_per_page: body["itemsPerPage"]
         }}

      {:error, _} = error ->
        error
    end
  end

  @doc "Fetches a video by GUID."
  @spec get(t() | keyword(), String.t()) :: {:ok, Video.t()} | {:error, Bunnyx.Error.t()}
  def get(client, video_id) do
    client = resolve(client)

    case Bunnyx.HTTP.request(
           client.req,
           :get,
           "/library/#{client.library_id}/videos/#{video_id}",
           []
         ) do
      {:ok, body} -> {:ok, Video.from_response(body)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Creates a video. The video must be uploaded separately with `upload/3`.

  ## Attributes

    * `:title` (required) — video title
    * `:collection_id` — collection to place the video in
    * `:thumbnail_time` — time in ms to extract the thumbnail from

  """
  @spec create(t() | keyword(), keyword()) :: {:ok, Video.t()} | {:error, Bunnyx.Error.t()}
  def create(client, attrs) do
    client = resolve(client)

    json = to_create_body(attrs)

    case Bunnyx.HTTP.request(client.req, :post, "/library/#{client.library_id}/videos",
           json: json
         ) do
      {:ok, body} -> {:ok, Video.from_response(body)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Updates a video's metadata.

  ## Attributes

    * `:title` — video title
    * `:collection_id` — collection ID
    * `:chapters` — list of chapter maps
    * `:moments` — list of moment maps
    * `:meta_tags` — list of meta tag maps

  """
  @spec update(t() | keyword(), String.t(), keyword()) ::
          {:ok, Video.t()} | {:error, Bunnyx.Error.t()}
  def update(client, video_id, attrs) do
    client = resolve(client)

    json = to_update_body(attrs)

    case Bunnyx.HTTP.request(
           client.req,
           :post,
           "/library/#{client.library_id}/videos/#{video_id}",
           json: json
         ) do
      {:ok, body} -> {:ok, Video.from_response(body)}
      {:error, _} = error -> error
    end
  end

  @doc "Deletes a video."
  @spec delete(t() | keyword(), String.t()) :: {:ok, nil} | {:error, Bunnyx.Error.t()}
  def delete(client, video_id) do
    client = resolve(client)

    case Bunnyx.HTTP.request(
           client.req,
           :delete,
           "/library/#{client.library_id}/videos/#{video_id}",
           []
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Uploads video data to a previously created video."
  @spec upload(t() | keyword(), String.t(), binary()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def upload(client, video_id, data) do
    client = resolve(client)

    case Bunnyx.HTTP.request(
           client.req,
           :put,
           "/library/#{client.library_id}/videos/#{video_id}",
           body: data
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc """
  Fetches a video from a URL for the library to download and encode.

  ## Attributes

    * `:url` (required) — source URL
    * `:title` — video title
    * `:headers` — headers to send with the fetch request

  """
  @spec fetch(t() | keyword(), keyword()) :: {:ok, Video.t()} | {:error, Bunnyx.Error.t()}
  def fetch(client, attrs) do
    client = resolve(client)

    json = to_fetch_body(attrs)

    case Bunnyx.HTTP.request(client.req, :post, "/library/#{client.library_id}/videos/fetch",
           json: json
         ) do
      {:ok, body} -> {:ok, Video.from_response(body)}
      {:error, _} = error -> error
    end
  end

  @create_mapping %{
    title: "title",
    collection_id: "collectionId",
    thumbnail_time: "thumbnailTime"
  }

  defp to_create_body(attrs) do
    Map.new(attrs, fn {key, value} ->
      {Map.fetch!(@create_mapping, key), value}
    end)
  end

  @update_mapping %{
    title: "title",
    collection_id: "collectionId",
    chapters: "chapters",
    moments: "moments",
    meta_tags: "metaTags"
  }

  defp to_update_body(attrs) do
    Map.new(attrs, fn {key, value} ->
      {Map.fetch!(@update_mapping, key), value}
    end)
  end

  @fetch_mapping %{url: "url", title: "title", headers: "headers"}

  defp to_fetch_body(attrs) do
    Map.new(attrs, fn {key, value} ->
      {Map.fetch!(@fetch_mapping, key), value}
    end)
  end

  defp to_query_params(opts) do
    mapping = %{
      page: "page",
      items_per_page: "itemsPerPage",
      search: "search",
      collection: "collection",
      order_by: "orderBy"
    }

    opts
    |> Keyword.take([:page, :items_per_page, :search, :collection, :order_by])
    |> Map.new(fn {key, value} ->
      {Map.fetch!(mapping, key), value}
    end)
  end

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)
end
