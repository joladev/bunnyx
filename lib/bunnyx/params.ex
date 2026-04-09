defmodule Bunnyx.Params do
  @moduledoc """
  Shared helpers for converting snake_case attrs to API-format maps.

  Used internally by all API modules to convert attrs (keyword list or map, e.g.
  `name: "my-zone"` or `%{name: "my-zone"}`) into the PascalCase maps the bunny.net
  API expects (e.g. `%{"Name" => "my-zone"}`). Unknown keys raise `ArgumentError`
  with the valid set listed.
  """

  @typedoc "Attributes accepted by create/update functions: keyword list or atom-keyed map."
  @type attrs :: keyword() | %{optional(atom()) => term()}

  @doc """
  Converts attrs (keyword list or map) to a map using the given key mapping.

  Raises `ArgumentError` with a clear message if an unknown key is passed.

  ## Examples

      iex> Bunnyx.Params.map_keys!([name: "test"], %{name: "Name"})
      %{"Name" => "test"}

      iex> Bunnyx.Params.map_keys!(%{name: "test"}, %{name: "Name"})
      %{"Name" => "test"}

      iex> Bunnyx.Params.map_keys!([bad: "x"], %{name: "Name"})
      ** (ArgumentError) unknown key :bad. Valid keys: [:name]

  """
  @spec map_keys!(attrs(), %{atom() => String.t()}) :: map()
  def map_keys!(attrs, mapping) do
    Map.new(attrs, fn {key, value} ->
      case Map.fetch(mapping, key) do
        {:ok, mapped} ->
          {mapped, value}

        :error ->
          valid =
            mapping
            |> Map.keys()
            |> Enum.sort()

          raise ArgumentError, "unknown key #{inspect(key)}. Valid keys: #{inspect(valid)}"
      end
    end)
  end

  @doc """
  Like `map_keys!/2` but only includes keys present in the mapping, ignoring extras.
  Useful for query param conversion where unknown keys should be silently dropped.
  """
  @spec map_keys(attrs(), %{atom() => String.t()}) :: map()
  def map_keys(attrs, mapping) do
    for {key, value} <- attrs, mapped = Map.get(mapping, key), into: %{} do
      {mapped, value}
    end
  end

  @doc "Puts a key-value pair into a keyword list only if the value is not nil."
  @spec maybe_put(keyword(), atom(), term()) :: keyword()
  def maybe_put(opts, _key, nil), do: opts
  def maybe_put(opts, key, value), do: Keyword.put(opts, key, value)

  @doc "Puts a key-value pair into a map only if the value is not nil."
  @spec maybe_put_map(map(), String.t(), term()) :: map()
  def maybe_put_map(map, _key, nil), do: map
  def maybe_put_map(map, key, value), do: Map.put(map, key, value)
end
