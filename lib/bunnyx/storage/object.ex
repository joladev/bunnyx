defmodule Bunnyx.Storage.Object do
  @moduledoc "File or directory entry returned by storage zone listing."

  @type t :: %__MODULE__{
          guid: String.t() | nil,
          storage_zone_name: String.t() | nil,
          path: String.t() | nil,
          object_name: String.t() | nil,
          length: integer() | nil,
          last_changed: String.t() | nil,
          is_directory: boolean() | nil,
          content_type: String.t() | nil,
          date_created: String.t() | nil,
          checksum: String.t() | nil
        }

  defstruct [
    :guid,
    :storage_zone_name,
    :path,
    :object_name,
    :length,
    :last_changed,
    :is_directory,
    :content_type,
    :date_created,
    :checksum
  ]

  @field_mapping %{
    "Guid" => :guid,
    "StorageZoneName" => :storage_zone_name,
    "Path" => :path,
    "ObjectName" => :object_name,
    "Length" => :length,
    "LastChanged" => :last_changed,
    "IsDirectory" => :is_directory,
    "ContentType" => :content_type,
    "DateCreated" => :date_created,
    "Checksum" => :checksum
  }

  @doc false
  def from_response(data) when is_map(data) do
    fields =
      for {pascal, atom} <- @field_mapping, Map.has_key?(data, pascal), into: %{} do
        {atom, data[pascal]}
      end

    struct(__MODULE__, fields)
  end
end
