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
      {:ok, body} when is_list(body) ->
        {:ok, body}

      {:ok, body} when is_map(body) ->
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
  @spec create(Bunnyx.t() | keyword(), Bunnyx.Params.attrs()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def create(client, attrs) do
    client = Bunnyx.resolve(client)

    json = Bunnyx.Params.map_keys!(attrs, @create_mapping)

    case Bunnyx.HTTP.request(client.req, :post, "/compute/script", json: json) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Updates an edge script."
  @spec update(Bunnyx.t() | keyword(), pos_integer(), Bunnyx.Params.attrs()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def update(client, id, attrs) do
    client = Bunnyx.resolve(client)

    json = Bunnyx.Params.map_keys!(attrs, @create_mapping)

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

  # -- Releases --

  @doc "Lists published releases for an edge script."
  @spec list_releases(Bunnyx.t() | keyword(), pos_integer(), keyword()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def list_releases(client, id, opts \\ []) do
    client = Bunnyx.resolve(client)
    params = to_page_params(opts)

    case Bunnyx.HTTP.request(client.req, :get, "/compute/script/#{id}/releases", params: params) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Returns the active release for an edge script."
  @spec get_active_release(Bunnyx.t() | keyword(), pos_integer()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def get_active_release(client, id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/compute/script/#{id}/releases/active", []) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc """
  Publishes a release for an edge script.

  ## Options

    * `:note` — release note
    * `:uuid` — specific release UUID to publish

  """
  @spec publish_release(Bunnyx.t() | keyword(), pos_integer(), keyword()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def publish_release(client, id, opts \\ []) do
    client = Bunnyx.resolve(client)

    json =
      %{}
      |> maybe_put("Note", opts[:note])
      |> maybe_put("Uuid", opts[:uuid])

    case Bunnyx.HTTP.request(client.req, :post, "/compute/script/#{id}/publish", json: json) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  # -- Secrets --

  @doc "Lists secrets for an edge script."
  @spec list_secrets(Bunnyx.t() | keyword(), pos_integer()) ::
          {:ok, list()} | {:error, Bunnyx.Error.t()}
  def list_secrets(client, id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/compute/script/#{id}/secrets", []) do
      {:ok, %{"Secrets" => secrets}} -> {:ok, secrets}
      {:ok, body} when is_list(body) -> {:ok, body}
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Adds a secret to an edge script."
  @spec add_secret(Bunnyx.t() | keyword(), pos_integer(), String.t(), String.t()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def add_secret(client, id, name, secret) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/compute/script/#{id}/secrets",
           json: %{"Name" => name, "Secret" => secret}
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Adds or updates a secret (upsert)."
  @spec upsert_secret(Bunnyx.t() | keyword(), pos_integer(), String.t(), String.t()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def upsert_secret(client, id, name, secret) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :put, "/compute/script/#{id}/secrets",
           json: %{"Name" => name, "Secret" => secret}
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Updates an existing secret."
  @spec update_secret(Bunnyx.t() | keyword(), pos_integer(), String.t(), String.t()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def update_secret(client, id, name, secret) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/compute/script/#{id}/secrets/#{name}",
           json: %{"Secret" => secret}
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Deletes a secret from an edge script."
  @spec delete_secret(Bunnyx.t() | keyword(), pos_integer(), pos_integer()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def delete_secret(client, id, secret_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(
           client.req,
           :delete,
           "/compute/script/#{id}/secrets/#{secret_id}",
           []
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  # -- Variables --

  @doc "Gets a variable by ID."
  @spec get_variable(Bunnyx.t() | keyword(), pos_integer(), pos_integer()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def get_variable(client, id, variable_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(
           client.req,
           :get,
           "/compute/script/#{id}/variables/#{variable_id}",
           []
         ) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Adds a variable to an edge script. Returns the created variable with its ID."
  @spec add_variable(Bunnyx.t() | keyword(), pos_integer(), Bunnyx.Params.attrs()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def add_variable(client, id, attrs) do
    client = Bunnyx.resolve(client)

    json = to_variable_body(attrs)

    case Bunnyx.HTTP.request(client.req, :post, "/compute/script/#{id}/variables/add", json: json) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Adds or updates a variable (upsert)."
  @spec upsert_variable(Bunnyx.t() | keyword(), pos_integer(), Bunnyx.Params.attrs()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def upsert_variable(client, id, attrs) do
    client = Bunnyx.resolve(client)

    json = to_variable_body(attrs)

    case Bunnyx.HTTP.request(client.req, :put, "/compute/script/#{id}/variables", json: json) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Updates an existing variable."
  @spec update_variable(
          Bunnyx.t() | keyword(),
          pos_integer(),
          pos_integer(),
          Bunnyx.Params.attrs()
        ) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def update_variable(client, id, variable_id, attrs) do
    client = Bunnyx.resolve(client)

    json = to_variable_body(attrs)

    case Bunnyx.HTTP.request(
           client.req,
           :post,
           "/compute/script/#{id}/variables/#{variable_id}",
           json: json
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Deletes a variable from an edge script."
  @spec delete_variable(Bunnyx.t() | keyword(), pos_integer(), pos_integer()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def delete_variable(client, id, variable_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(
           client.req,
           :delete,
           "/compute/script/#{id}/variables/#{variable_id}",
           []
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @variable_mapping %{
    name: "Name",
    required: "Required",
    default_value: "DefaultValue"
  }

  defp to_variable_body(attrs) do
    Bunnyx.Params.map_keys!(attrs, @variable_mapping)
  end

  defp to_page_params(opts) do
    mapping = %{page: "page", per_page: "perPage"}

    opts
    |> Keyword.take([:page, :per_page])
    |> Map.new(fn {key, value} ->
      {Map.fetch!(mapping, key), value}
    end)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp to_query_params(opts) do
    mapping = %{page: "page", per_page: "perPage", search: "search", type: "type"}

    opts
    |> Keyword.take([:page, :per_page, :search, :type])
    |> Map.new(fn {key, value} ->
      {Map.fetch!(mapping, key), value}
    end)
  end
end
