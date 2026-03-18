defmodule Bunnyx.EdgeScript do
  @moduledoc """
  Edge scripting — deploy and manage JavaScript/TypeScript code at the edge.

  Uses the main API client created with `Bunnyx.new/1`.

  ## Usage

      client = Bunnyx.new(api_key: "sk-...")

      {:ok, script} = Bunnyx.EdgeScript.create(client, name: "my-script", script_type: 1)
      {:ok, nil} = Bunnyx.EdgeScript.set_code(client, script["Id"], "export default { fetch() {} }")
      {:ok, scripts} = Bunnyx.EdgeScript.list(client)
  """

  @create_mapping %{
    name: "Name",
    code: "Code",
    script_type: "ScriptType",
    create_linked_pull_zone: "CreateLinkedPullZone",
    linked_pull_zone_name: "LinkedPullZoneName"
  }

  @doc """
  Lists edge scripts.

  ## Options

    * `:page` — page number
    * `:per_page` — items per page
    * `:search` — search term
    * `:type` — filter by script type (0 = DNS, 1 = CDN, 2 = Middleware)

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
    params = to_query_params(opts)

    case Bunnyx.HTTP.request(client.req, :get, "/compute/script", params: params) do
      {:ok, body} ->
        {:ok,
         %{
           items: body["Items"],
           current_page: body["CurrentPage"],
           total_items: body["TotalItems"],
           has_more_items: body["HasMoreItems"]
         }}

      {:error, _} = error ->
        error
    end
  end

  @doc "Fetches an edge script by ID."
  @spec get(Bunnyx.t() | keyword(), pos_integer()) :: {:ok, map()} | {:error, Bunnyx.Error.t()}
  def get(client, id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/compute/script/#{id}", []) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc """
  Creates an edge script.

  ## Attributes

    * `:name` — script name (max 100 chars)
    * `:script_type` (required) — 0 = DNS, 1 = CDN, 2 = Middleware
    * `:code` — initial code
    * `:create_linked_pull_zone` — auto-create a linked pull zone
    * `:linked_pull_zone_name` — name for the linked pull zone

  """
  @spec create(Bunnyx.t() | keyword(), keyword()) :: {:ok, map()} | {:error, Bunnyx.Error.t()}
  def create(client, attrs) do
    client = Bunnyx.resolve(client)

    json =
      Map.new(attrs, fn {key, value} ->
        {Map.fetch!(@create_mapping, key), value}
      end)

    case Bunnyx.HTTP.request(client.req, :post, "/compute/script", json: json) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Updates an edge script."
  @spec update(Bunnyx.t() | keyword(), pos_integer(), keyword()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def update(client, id, attrs) do
    client = Bunnyx.resolve(client)

    json =
      Map.new(attrs, fn {key, value} ->
        {Map.fetch!(@create_mapping, key), value}
      end)

    case Bunnyx.HTTP.request(client.req, :post, "/compute/script/#{id}", json: json) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Deletes an edge script."
  @spec delete(Bunnyx.t() | keyword(), pos_integer()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def delete(client, id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :delete, "/compute/script/#{id}", []) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Returns statistics for an edge script."
  @spec statistics(Bunnyx.t() | keyword(), pos_integer()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def statistics(client, id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/compute/script/#{id}/statistics", []) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Rotates the deployment key for an edge script."
  @spec rotate_deployment_key(Bunnyx.t() | keyword(), pos_integer()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def rotate_deployment_key(client, id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/compute/script/#{id}/deploymentKey/rotate", []) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Returns the current code for an edge script."
  @spec get_code(Bunnyx.t() | keyword(), pos_integer()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def get_code(client, id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/compute/script/#{id}/code", []) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Sets the code for an edge script."
  @spec set_code(Bunnyx.t() | keyword(), pos_integer(), String.t()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def set_code(client, id, code) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/compute/script/#{id}/code",
           json: %{"Code" => code}
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  defp to_query_params(opts) do
    mapping = %{page: "page", per_page: "perPage", search: "search", type: "type"}

    opts
    |> Keyword.take([:page, :per_page, :search, :type])
    |> Map.new(fn {key, value} ->
      {Map.fetch!(mapping, key), value}
    end)
  end
end
