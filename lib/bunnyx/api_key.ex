defmodule Bunnyx.ApiKey do
  @moduledoc """
  API key management. Lists the API keys associated with your account.

  Uses the main API client created with `Bunnyx.new/1`.

  ## Usage

      client = Bunnyx.new(api_key: "sk-...")

      {:ok, page} = Bunnyx.ApiKey.list(client)
  """

  @field_mapping %{
    "Id" => :id,
    "Key" => :key,
    "Roles" => :roles
  }

  @doc """
  Lists API keys.

  ## Options

    * `:page` — page number
    * `:per_page` — items per page

  """
  @spec list(Bunnyx.t() | keyword(), keyword()) ::
          {:ok,
           %{
             items: [map()],
             current_page: integer(),
             total_items: integer(),
             has_more_items: boolean()
           }}
          | {:error, Bunnyx.Error.t()}
  def list(client, opts \\ []) do
    client = Bunnyx.resolve(client)

    params =
      opts
      |> Keyword.take([:page, :per_page])
      |> to_query_params()

    case Bunnyx.HTTP.request(client.req, :get, "/apikey", params: params) do
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

  defp from_response(data) when is_map(data) do
    for {pascal, atom} <- @field_mapping, Map.has_key?(data, pascal), into: %{} do
      {atom, data[pascal]}
    end
  end

  defp to_query_params(opts) do
    mapping = %{page: "page", per_page: "perPage"}

    Map.new(opts, fn {key, value} ->
      {Map.fetch!(mapping, key), value}
    end)
  end
end
