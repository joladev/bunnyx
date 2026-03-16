defmodule Bunnyx.VideoLibrary do
  @moduledoc """
  Stream video libraries. A video library is a container for videos that handles
  encoding, storage, and delivery through bunny.net's Stream platform.

  Uses the main API client created with `Bunnyx.new/1`.

  ## Usage

      client = Bunnyx.new(api_key: "sk-...")

      {:ok, lib} = Bunnyx.VideoLibrary.create(client, name: "my-library")
      {:ok, lib} = Bunnyx.VideoLibrary.get(client, lib.id)
      {:ok, page} = Bunnyx.VideoLibrary.list(client)
      {:ok, lib} = Bunnyx.VideoLibrary.update(client, lib.id, enable_transcribing: true)
      {:ok, nil} = Bunnyx.VideoLibrary.delete(client, lib.id)
  """

  @type t :: %__MODULE__{
          id: pos_integer() | nil,
          name: String.t() | nil,
          video_count: integer() | nil,
          traffic_usage: integer() | nil,
          storage_usage: integer() | nil,
          date_created: String.t() | nil,
          date_modified: String.t() | nil,
          replication_regions: [String.t()] | nil,
          api_key: String.t() | nil,
          read_only_api_key: String.t() | nil,
          has_watermark: boolean() | nil,
          pull_zone_id: integer() | nil,
          storage_zone_id: integer() | nil,
          enabled_resolutions: String.t() | nil,
          webhook_url: String.t() | nil,
          allowed_referrers: [String.t()] | nil,
          blocked_referrers: [String.t()] | nil,
          player_token_authentication_enabled: boolean() | nil,
          enable_mp4_fallback: boolean() | nil,
          keep_original_files: boolean() | nil,
          allow_direct_play: boolean() | nil,
          enable_drm: boolean() | nil,
          enable_transcribing: boolean() | nil,
          ui_language: String.t() | nil,
          player_key_color: String.t() | nil
        }

  defstruct [
    :id,
    :name,
    :video_count,
    :traffic_usage,
    :storage_usage,
    :date_created,
    :date_modified,
    :replication_regions,
    :api_key,
    :read_only_api_key,
    :has_watermark,
    :pull_zone_id,
    :storage_zone_id,
    :enabled_resolutions,
    :webhook_url,
    :allowed_referrers,
    :blocked_referrers,
    :player_token_authentication_enabled,
    :enable_mp4_fallback,
    :keep_original_files,
    :allow_direct_play,
    :enable_drm,
    :enable_transcribing,
    :ui_language,
    :player_key_color
  ]

  @field_mapping %{
    "Id" => :id,
    "Name" => :name,
    "VideoCount" => :video_count,
    "TrafficUsage" => :traffic_usage,
    "StorageUsage" => :storage_usage,
    "DateCreated" => :date_created,
    "DateModified" => :date_modified,
    "ReplicationRegions" => :replication_regions,
    "ApiKey" => :api_key,
    "ReadOnlyApiKey" => :read_only_api_key,
    "HasWatermark" => :has_watermark,
    "PullZoneId" => :pull_zone_id,
    "StorageZoneId" => :storage_zone_id,
    "EnabledResolutions" => :enabled_resolutions,
    "WebhookUrl" => :webhook_url,
    "AllowedReferrers" => :allowed_referrers,
    "BlockedReferrers" => :blocked_referrers,
    "PlayerTokenAuthenticationEnabled" => :player_token_authentication_enabled,
    "EnableMP4Fallback" => :enable_mp4_fallback,
    "KeepOriginalFiles" => :keep_original_files,
    "AllowDirectPlay" => :allow_direct_play,
    "EnableDRM" => :enable_drm,
    "EnableTranscribing" => :enable_transcribing,
    "UILanguage" => :ui_language,
    "PlayerKeyColor" => :player_key_color,
    # Write-only: used in create request
    "PlayerVersion" => :player_version
  }

  @reverse_mapping Map.new(@field_mapping, fn {pascal, atom} -> {atom, pascal} end)

  @doc """
  Lists video libraries.

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

    case Bunnyx.HTTP.request(client.req, :get, "/videolibrary", params: params) do
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

  @doc "Fetches a video library by ID."
  @spec get(Bunnyx.t() | keyword(), pos_integer()) :: {:ok, t()} | {:error, Bunnyx.Error.t()}
  def get(client, id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/videolibrary/#{id}", []) do
      {:ok, body} -> {:ok, from_response(body)}
      {:error, _} = error -> error
    end
  end

  @doc "Creates a video library with the given attributes."
  @spec create(Bunnyx.t() | keyword(), keyword()) :: {:ok, t()} | {:error, Bunnyx.Error.t()}
  def create(client, attrs) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/videolibrary", json: to_request_body(attrs)) do
      {:ok, body} -> {:ok, from_response(body)}
      {:error, _} = error -> error
    end
  end

  @doc "Updates a video library."
  @spec update(Bunnyx.t() | keyword(), pos_integer(), keyword()) ::
          {:ok, t()} | {:error, Bunnyx.Error.t()}
  def update(client, id, attrs) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/videolibrary/#{id}",
           json: to_request_body(attrs)
         ) do
      {:ok, body} -> {:ok, from_response(body)}
      {:error, _} = error -> error
    end
  end

  @doc "Deletes a video library."
  @spec delete(Bunnyx.t() | keyword(), pos_integer()) :: {:ok, nil} | {:error, Bunnyx.Error.t()}
  def delete(client, id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :delete, "/videolibrary/#{id}", []) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Resets the API key for a specific video library."
  @spec reset_api_key(Bunnyx.t() | keyword(), pos_integer()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def reset_api_key(client, id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/videolibrary/#{id}/resetApiKey", []) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Resets the API key for all video libraries."
  @spec reset_all_api_keys(Bunnyx.t() | keyword()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def reset_all_api_keys(client) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/videolibrary/resetApiKey", []) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Resets the read-only API key for a specific video library."
  @spec reset_read_only_api_key(Bunnyx.t() | keyword(), pos_integer()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def reset_read_only_api_key(client, id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/videolibrary/#{id}/resetReadOnlyApiKey", []) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Resets the read-only API key for all video libraries."
  @spec reset_all_read_only_api_keys(Bunnyx.t() | keyword()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def reset_all_read_only_api_keys(client) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/videolibrary/resetReadOnlyApiKey", []) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Uploads a watermark image for a video library."
  @spec add_watermark(Bunnyx.t() | keyword(), pos_integer(), binary()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def add_watermark(client, id, image_data) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :put, "/videolibrary/#{id}/watermark", body: image_data) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Removes the watermark from a video library."
  @spec remove_watermark(Bunnyx.t() | keyword(), pos_integer()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def remove_watermark(client, id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :delete, "/videolibrary/#{id}/watermark", []) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Adds a hostname to the video library's allowed referrer list."
  @spec add_allowed_referrer(Bunnyx.t() | keyword(), pos_integer(), String.t()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def add_allowed_referrer(client, id, hostname) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/videolibrary/#{id}/addAllowedReferrer",
           json: %{"Hostname" => hostname}
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Removes a hostname from the video library's allowed referrer list."
  @spec remove_allowed_referrer(Bunnyx.t() | keyword(), pos_integer(), String.t()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def remove_allowed_referrer(client, id, hostname) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/videolibrary/#{id}/removeAllowedReferrer",
           json: %{"Hostname" => hostname}
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Adds a hostname to the video library's blocked referrer list."
  @spec add_blocked_referrer(Bunnyx.t() | keyword(), pos_integer(), String.t()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def add_blocked_referrer(client, id, hostname) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/videolibrary/#{id}/addBlockedReferrer",
           json: %{"Hostname" => hostname}
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Removes a hostname from the video library's blocked referrer list."
  @spec remove_blocked_referrer(Bunnyx.t() | keyword(), pos_integer(), String.t()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def remove_blocked_referrer(client, id, hostname) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/videolibrary/#{id}/removeBlockedReferrer",
           json: %{"Hostname" => hostname}
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc """
  Returns transcription statistics for a video library.

  ## Options

    * `:date_from` — start date (ISO 8601 string)
    * `:date_to` — end date (ISO 8601 string)

  """
  @spec transcribing_statistics(Bunnyx.t() | keyword(), pos_integer(), keyword()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def transcribing_statistics(client, id, opts \\ []) do
    client = Bunnyx.resolve(client)

    params =
      opts
      |> Keyword.take([:date_from, :date_to])
      |> to_statistics_params()

    case Bunnyx.HTTP.request(client.req, :get, "/videolibrary/#{id}/transcribing/statistics",
           params: params
         ) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Lists available languages for transcription and captions."
  @spec languages(Bunnyx.t() | keyword()) :: {:ok, list()} | {:error, Bunnyx.Error.t()}
  def languages(client) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/videolibrary/languages", []) do
      {:ok, body} -> {:ok, body}
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

  defp to_statistics_params(opts) do
    mapping = %{date_from: "dateFrom", date_to: "dateTo"}

    Map.new(opts, fn {key, value} ->
      {Map.fetch!(mapping, key), value}
    end)
  end

  defp to_query_params(opts) do
    mapping = %{page: "page", per_page: "perPage", search: "search"}

    Map.new(opts, fn {key, value} ->
      {Map.fetch!(mapping, key), value}
    end)
  end
end
