defmodule Bunnyx.Stream.Collection do
  @moduledoc """
  A collection in a Stream library. Collections organize videos into groups.
  """

  @type t :: %__MODULE__{
          guid: String.t() | nil,
          name: String.t() | nil,
          video_library_id: pos_integer() | nil,
          video_count: integer() | nil,
          total_size: integer() | nil,
          preview_video_ids: String.t() | nil,
          preview_image_urls: [String.t()] | nil
        }

  defstruct [
    :guid,
    :name,
    :video_library_id,
    :video_count,
    :total_size,
    :preview_video_ids,
    :preview_image_urls
  ]

  @field_mapping %{
    "guid" => :guid,
    "name" => :name,
    "videoLibraryId" => :video_library_id,
    "videoCount" => :video_count,
    "totalSize" => :total_size,
    "previewVideoIds" => :preview_video_ids,
    "previewImageUrls" => :preview_image_urls
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
