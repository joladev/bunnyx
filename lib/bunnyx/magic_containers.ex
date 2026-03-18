defmodule Bunnyx.MagicContainers do
  @moduledoc """
  Magic Containers — deploy and manage containerized applications at bunny.net's edge.

  Uses the main API client created with `Bunnyx.new/1`. All endpoints are under `/mc/`.

  ## Usage

      client = Bunnyx.new(api_key: "sk-...")

      {:ok, app} = Bunnyx.MagicContainers.create(client, %{"name" => "my-app", ...})
      {:ok, nil} = Bunnyx.MagicContainers.deploy(client, app["id"])
      {:ok, apps} = Bunnyx.MagicContainers.list(client)
  """

  @doc """
  Lists applications.

  ## Options

    * `:limit` — results per page (1–1000, default 20)
    * `:next_cursor` — pagination cursor

  """
  @spec list(Bunnyx.t() | keyword(), keyword()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def list(client, opts \\ []) do
    client = Bunnyx.resolve(client)
    params = to_list_params(opts)

    case Bunnyx.HTTP.request(client.req, :get, "/mc/apps", params: params) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Fetches an application by ID."
  @spec get(Bunnyx.t() | keyword(), String.t()) :: {:ok, map()} | {:error, Bunnyx.Error.t()}
  def get(client, app_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/mc/apps/#{app_id}", []) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Creates an application. Pass the full config as a map (camelCase keys)."
  @spec create(Bunnyx.t() | keyword(), map()) :: {:ok, map()} | {:error, Bunnyx.Error.t()}
  def create(client, config) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/mc/apps", json: config) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Replaces the full application configuration."
  @spec update(Bunnyx.t() | keyword(), String.t(), map()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def update(client, app_id, config) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :put, "/mc/apps/#{app_id}", json: config) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Partially updates an application (JSON Merge Patch)."
  @spec patch(Bunnyx.t() | keyword(), String.t(), map()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def patch(client, app_id, changes) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :patch, "/mc/apps/#{app_id}", json: changes) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Deletes an application."
  @spec delete(Bunnyx.t() | keyword(), String.t()) :: {:ok, nil} | {:error, Bunnyx.Error.t()}
  def delete(client, app_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :delete, "/mc/apps/#{app_id}", []) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Deploys an application."
  @spec deploy(Bunnyx.t() | keyword(), String.t()) :: {:ok, nil} | {:error, Bunnyx.Error.t()}
  def deploy(client, app_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/mc/apps/#{app_id}/deploy", []) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Undeploys an application (stops all running instances)."
  @spec undeploy(Bunnyx.t() | keyword(), String.t()) :: {:ok, nil} | {:error, Bunnyx.Error.t()}
  def undeploy(client, app_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/mc/apps/#{app_id}/undeploy", []) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Restarts all pods for an application."
  @spec restart(Bunnyx.t() | keyword(), String.t()) :: {:ok, nil} | {:error, Bunnyx.Error.t()}
  def restart(client, app_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/mc/apps/#{app_id}/restart", []) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Returns an overview for an application."
  @spec overview(Bunnyx.t() | keyword(), String.t()) :: {:ok, map()} | {:error, Bunnyx.Error.t()}
  def overview(client, app_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/mc/apps/#{app_id}/overview", []) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Returns statistics for an application."
  @spec statistics(Bunnyx.t() | keyword(), String.t()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def statistics(client, app_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/mc/apps/#{app_id}/statistics", []) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  defp to_list_params(opts) do
    mapping = %{limit: "limit", next_cursor: "nextCursor"}

    opts
    |> Keyword.take([:limit, :next_cursor])
    |> Map.new(fn {key, value} ->
      {Map.fetch!(mapping, key), value}
    end)
  end
end
