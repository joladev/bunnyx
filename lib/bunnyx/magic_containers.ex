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

  # -- Container Registries --

  @doc "Lists all container registries."
  @spec list_registries(Bunnyx.t() | keyword()) :: {:ok, list()} | {:error, Bunnyx.Error.t()}
  def list_registries(client) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/mc/registries", []) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Gets a container registry by ID."
  @spec get_registry(Bunnyx.t() | keyword(), pos_integer()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def get_registry(client, registry_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/mc/registries/#{registry_id}", []) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Adds a container registry."
  @spec add_registry(Bunnyx.t() | keyword(), map()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def add_registry(client, config) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/mc/registries", json: config) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Updates a container registry."
  @spec update_registry(Bunnyx.t() | keyword(), pos_integer(), map()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def update_registry(client, registry_id, config) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :put, "/mc/registries/#{registry_id}", json: config) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Deletes a container registry."
  @spec delete_registry(Bunnyx.t() | keyword(), pos_integer()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def delete_registry(client, registry_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :delete, "/mc/registries/#{registry_id}", []) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Lists container images in a private registry."
  @spec list_images(Bunnyx.t() | keyword(), map()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def list_images(client, body) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/mc/registries/images", json: body) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Lists tags for a container image."
  @spec list_image_tags(Bunnyx.t() | keyword(), map()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def list_image_tags(client, body) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/mc/registries/images/tags", json: body) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Gets the digest for a container image."
  @spec get_image_digest(Bunnyx.t() | keyword(), map()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def get_image_digest(client, body) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/mc/registries/images/digest", json: body) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Searches for public container images."
  @spec search_public_images(Bunnyx.t() | keyword(), map()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def search_public_images(client, body) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/mc/registries/public-images/search", json: body) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Gets container config suggestions for an image."
  @spec get_config_suggestions(Bunnyx.t() | keyword(), map()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def get_config_suggestions(client, body) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/mc/registries/config-suggestions", json: body) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  # -- Container Templates --

  @doc "Adds a container template to an application."
  @spec add_container(Bunnyx.t() | keyword(), String.t(), map()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def add_container(client, app_id, config) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/mc/apps/#{app_id}/containers", json: config) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Gets a container template."
  @spec get_container(Bunnyx.t() | keyword(), String.t(), String.t()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def get_container(client, app_id, container_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(
           client.req,
           :get,
           "/mc/apps/#{app_id}/containers/#{container_id}",
           []
         ) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Patches a container template."
  @spec patch_container(Bunnyx.t() | keyword(), String.t(), String.t(), map()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def patch_container(client, app_id, container_id, changes) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(
           client.req,
           :patch,
           "/mc/apps/#{app_id}/containers/#{container_id}",
           json: changes
         ) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Deletes a container template."
  @spec delete_container(Bunnyx.t() | keyword(), String.t(), String.t()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def delete_container(client, app_id, container_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(
           client.req,
           :delete,
           "/mc/apps/#{app_id}/containers/#{container_id}",
           []
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Replaces all environment variables for a container template."
  @spec set_container_env(Bunnyx.t() | keyword(), String.t(), String.t(), list()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def set_container_env(client, app_id, container_id, env_vars) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(
           client.req,
           :put,
           "/mc/apps/#{app_id}/containers/#{container_id}/env",
           json: env_vars
         ) do
      {:ok, _} -> {:ok, nil}
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
