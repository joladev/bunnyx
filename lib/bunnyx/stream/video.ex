defmodule Bunnyx.Stream.Video do
  @moduledoc """
  A video in a Stream library. Maps camelCase API fields to snake_case Elixir fields.
  """

  @type t :: %__MODULE__{
          guid: String.t() | nil,
          title: String.t() | nil,
          description: String.t() | nil,
          video_library_id: pos_integer() | nil,
          date_uploaded: String.t() | nil,
          views: integer() | nil,
          is_public: boolean() | nil,
          length: integer() | nil,
          status: integer() | nil,
          framerate: number() | nil,
          width: integer() | nil,
          height: integer() | nil,
          available_resolutions: String.t() | nil,
          encode_progress: integer() | nil,
          storage_size: integer() | nil,
          has_mp4_fallback: boolean() | nil,
          collection_id: String.t() | nil,
          thumbnail_file_name: String.t() | nil,
          average_watch_time: integer() | nil,
          total_watch_time: integer() | nil,
          category: String.t() | nil,
          has_original: boolean() | nil
        }

  defstruct [
    :guid,
    :title,
    :description,
    :video_library_id,
    :date_uploaded,
    :views,
    :is_public,
    :length,
    :status,
    :framerate,
    :width,
    :height,
    :available_resolutions,
    :encode_progress,
    :storage_size,
    :has_mp4_fallback,
    :collection_id,
    :thumbnail_file_name,
    :average_watch_time,
    :total_watch_time,
    :category,
    :has_original
  ]

  @field_mapping %{
    "guid" => :guid,
    "title" => :title,
    "description" => :description,
    "videoLibraryId" => :video_library_id,
    "dateUploaded" => :date_uploaded,
    "views" => :views,
    "isPublic" => :is_public,
    "length" => :length,
    "status" => :status,
    "framerate" => :framerate,
    "width" => :width,
    "height" => :height,
    "availableResolutions" => :available_resolutions,
    "encodeProgress" => :encode_progress,
    "storageSize" => :storage_size,
    "hasMP4Fallback" => :has_mp4_fallback,
    "collectionId" => :collection_id,
    "thumbnailFileName" => :thumbnail_file_name,
    "averageWatchTime" => :average_watch_time,
    "totalWatchTime" => :total_watch_time,
    "category" => :category,
    "hasOriginal" => :has_original
  }

  @doc false
  @spec from_response(map()) :: t()
  def from_response(data) when is_map(data) do
    fields =
      for {camel, atom} <- @field_mapping, Map.has_key?(data, camel), into: %{} do
        {atom, data[camel]}
      end

    struct(__MODULE__, fields)
  end
end
