defmodule Bunnyx.MagicContainers.App do
  @moduledoc """
  A Magic Containers application. Maps camelCase API fields to snake_case.

  Nested objects (container templates, volumes, region settings, autoscaling)
  are kept as raw maps.
  """

  @type t :: %__MODULE__{
          id: String.t() | nil,
          name: String.t() | nil,
          status: String.t() | nil,
          runtime_type: String.t() | nil,
          display_endpoint: map() | nil,
          auto_scaling: map() | nil,
          region_settings: map() | nil,
          network_settings: map() | nil,
          container_templates: [map()] | nil,
          container_instances: [map()] | nil,
          volumes: [map()] | nil
        }

  defstruct [
    :id,
    :name,
    :status,
    :runtime_type,
    :display_endpoint,
    :auto_scaling,
    :region_settings,
    :network_settings,
    :container_templates,
    :container_instances,
    :volumes
  ]

  @field_mapping %{
    "id" => :id,
    "name" => :name,
    "status" => :status,
    "runtimeType" => :runtime_type,
    "displayEndpoint" => :display_endpoint,
    "autoScaling" => :auto_scaling,
    "regionSettings" => :region_settings,
    "networkSettings" => :network_settings,
    "containerTemplates" => :container_templates,
    "containerInstances" => :container_instances,
    "volumes" => :volumes
  }

  @reverse_mapping Map.new(@field_mapping, fn {camel, atom} -> {atom, camel} end)

  @doc false
  @spec from_response(map()) :: t()
  def from_response(data) when is_map(data) do
    fields =
      for {camel, atom} <- @field_mapping, Map.has_key?(data, camel), into: %{} do
        {atom, data[camel]}
      end

    struct(__MODULE__, fields)
  end

  @doc false
  @spec to_request_body(Bunnyx.Params.attrs()) :: map()
  def to_request_body(attrs) do
    Bunnyx.Params.map_keys!(attrs, @reverse_mapping)
  end
end
