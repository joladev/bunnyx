defmodule Bunnyx.MagicContainers do
  @moduledoc """
  Magic Containers — deploy and manage containerized applications at bunny.net's edge.

  Uses the main API client created with `Bunnyx.new/1`. All endpoints are under `/mc/`.

  ## Usage

      client = Bunnyx.new(api_key: "sk-...")

      {:ok, app} = Bunnyx.MagicContainers.create(client,
        name: "my-app",
        runtime_type: "Shared",
        auto_scaling: %{"minReplicas" => 1, "maxReplicas" => 3},
        region_settings: %{"baseRegion" => "DE"}
      )

      {:ok, nil} = Bunnyx.MagicContainers.deploy(client, app.id)
      {:ok, apps} = Bunnyx.MagicContainers.list(client)
  """

  alias Bunnyx.MagicContainers.App

  @doc """
  Lists applications.

  ## Options

    * `:per_page` — results per page (1–1000, default 20)
    * `:next_cursor` — pagination cursor

  """
  @spec list(Bunnyx.t() | keyword(), keyword()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def list(client, opts \\ []) do
    client = Bunnyx.resolve(client)
    params = to_list_params(opts)

    case Bunnyx.HTTP.request(client.req, :get, "/mc/apps", params: params) do
      {:ok, body} ->
        items =
          body
          |> Map.get("data", [])
          |> Enum.map(&App.from_response/1)

        {:ok, Map.put(body, "data", items)}

      {:error, _} = error ->
        error
    end
  end

  @doc "Fetches an application by ID."
  @spec get(Bunnyx.t() | keyword(), String.t()) ::
          {:ok, App.t()} | {:error, Bunnyx.Error.t()}
  def get(client, app_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/mc/apps/#{app_id}", []) do
      {:ok, body} -> {:ok, App.from_response(body)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Creates an application.

  ## Attributes

    * `:name` (required) — app name
    * `:runtime_type` (required) — `"Shared"` or `"Reserved"`
    * `:auto_scaling` — autoscaling config map (camelCase keys)
    * `:region_settings` — region config map (camelCase keys)
    * `:container_templates` — list of container config maps
    * `:volumes` — list of volume config maps

  """
  @spec create(Bunnyx.t() | keyword(), Bunnyx.Params.attrs()) ::
          {:ok, App.t()} | {:error, Bunnyx.Error.t()}
  def create(client, attrs) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/mc/apps", json: App.to_request_body(attrs)) do
      {:ok, body} -> {:ok, App.from_response(body)}
      {:error, _} = error -> error
    end
  end

  @doc "Replaces the full application configuration."
  @spec update(Bunnyx.t() | keyword(), String.t(), Bunnyx.Params.attrs()) ::
          {:ok, App.t()} | {:error, Bunnyx.Error.t()}
  def update(client, app_id, attrs) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :put, "/mc/apps/#{app_id}",
           json: App.to_request_body(attrs)
         ) do
      {:ok, body} -> {:ok, App.from_response(body)}
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

  # -- Endpoints --

  @doc "Lists endpoints for all containers in an application."
  @spec list_endpoints(Bunnyx.t() | keyword(), String.t()) ::
          {:ok, list()} | {:error, Bunnyx.Error.t()}
  def list_endpoints(client, app_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/mc/apps/#{app_id}/endpoints", []) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Adds an endpoint to a container."
  @spec add_endpoint(Bunnyx.t() | keyword(), String.t(), String.t(), map()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def add_endpoint(client, app_id, container_id, config) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(
           client.req,
           :post,
           "/mc/apps/#{app_id}/containers/#{container_id}/endpoints",
           json: config
         ) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Updates an endpoint."
  @spec update_endpoint(Bunnyx.t() | keyword(), String.t(), String.t(), map()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def update_endpoint(client, app_id, endpoint_id, config) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(
           client.req,
           :put,
           "/mc/apps/#{app_id}/endpoints/#{endpoint_id}",
           json: config
         ) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Deletes an endpoint."
  @spec delete_endpoint(Bunnyx.t() | keyword(), String.t(), String.t()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def delete_endpoint(client, app_id, endpoint_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(
           client.req,
           :delete,
           "/mc/apps/#{app_id}/endpoints/#{endpoint_id}",
           []
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  # -- Autoscaling --

  @doc "Gets autoscaling settings for an application."
  @spec get_autoscaling(Bunnyx.t() | keyword(), String.t()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def get_autoscaling(client, app_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/mc/apps/#{app_id}/autoscaling", []) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Updates autoscaling settings for an application."
  @spec update_autoscaling(Bunnyx.t() | keyword(), String.t(), map()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def update_autoscaling(client, app_id, config) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :put, "/mc/apps/#{app_id}/autoscaling", json: config) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  # -- Regions --

  @doc "Lists all available deployment regions."
  @spec list_regions(Bunnyx.t() | keyword()) :: {:ok, list()} | {:error, Bunnyx.Error.t()}
  def list_regions(client) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/mc/regions", []) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Gets the optimal base region based on CDN server token."
  @spec get_optimal_region(Bunnyx.t() | keyword(), String.t()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def get_optimal_region(client, cdn_server_token) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/mc/regions/optimal",
           params: %{"cdnServerToken" => cdn_server_token}
         ) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Gets region settings for an application."
  @spec get_region_settings(Bunnyx.t() | keyword(), String.t()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def get_region_settings(client, app_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/mc/apps/#{app_id}/regions", []) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Updates region settings for an application."
  @spec update_region_settings(Bunnyx.t() | keyword(), String.t(), map()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def update_region_settings(client, app_id, config) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :put, "/mc/apps/#{app_id}/regions", json: config) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  # -- Volumes --

  @doc "Lists volumes for an application."
  @spec list_volumes(Bunnyx.t() | keyword(), String.t()) ::
          {:ok, list()} | {:error, Bunnyx.Error.t()}
  def list_volumes(client, app_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/mc/apps/#{app_id}/volumes", []) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Updates a volume."
  @spec update_volume(Bunnyx.t() | keyword(), String.t(), String.t(), map()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def update_volume(client, app_id, volume_id, config) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(
           client.req,
           :put,
           "/mc/apps/#{app_id}/volumes/#{volume_id}",
           json: config
         ) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Detaches a volume from its container."
  @spec detach_volume(Bunnyx.t() | keyword(), String.t(), String.t()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def detach_volume(client, app_id, volume_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(
           client.req,
           :post,
           "/mc/apps/#{app_id}/volumes/#{volume_id}/detach",
           []
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Deletes a specific volume instance."
  @spec delete_volume_instance(Bunnyx.t() | keyword(), String.t(), String.t(), String.t()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def delete_volume_instance(client, app_id, volume_id, instance_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(
           client.req,
           :delete,
           "/mc/apps/#{app_id}/volumes/#{volume_id}/instances/#{instance_id}",
           []
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Deletes all instances of a volume."
  @spec delete_all_volume_instances(Bunnyx.t() | keyword(), String.t(), String.t()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def delete_all_volume_instances(client, app_id, volume_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(
           client.req,
           :delete,
           "/mc/apps/#{app_id}/volumes/#{volume_id}/instances",
           []
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  # -- Nodes --

  @doc "Lists all node IP addresses in the Magic Containers network."
  @spec list_nodes(Bunnyx.t() | keyword(), keyword()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def list_nodes(client, opts \\ []) do
    client = Bunnyx.resolve(client)
    params = to_list_params(opts)

    case Bunnyx.HTTP.request(client.req, :get, "/mc/nodes", params: params) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  # -- Pods --

  @doc "Recreates a pod (deletes and re-creates it)."
  @spec recreate_pod(Bunnyx.t() | keyword(), String.t(), String.t()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def recreate_pod(client, app_id, pod_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(
           client.req,
           :post,
           "/mc/apps/#{app_id}/pods/#{pod_id}/recreate",
           []
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  # -- Limits --

  @doc "Gets resource limits and usage for the authenticated user."
  @spec get_limits(Bunnyx.t() | keyword()) :: {:ok, map()} | {:error, Bunnyx.Error.t()}
  def get_limits(client) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/mc/limits", []) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  # -- Log Forwarding --

  @doc "Lists log forwarding configurations."
  @spec list_log_forwarding(Bunnyx.t() | keyword()) ::
          {:ok, list()} | {:error, Bunnyx.Error.t()}
  def list_log_forwarding(client) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/mc/log/forwarding", []) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Gets a log forwarding configuration."
  @spec get_log_forwarding(Bunnyx.t() | keyword(), String.t()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def get_log_forwarding(client, config_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/mc/log/forwarding/#{config_id}", []) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Creates a log forwarding configuration."
  @spec create_log_forwarding(Bunnyx.t() | keyword(), map()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def create_log_forwarding(client, config) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/mc/log/forwarding", json: config) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Updates a log forwarding configuration."
  @spec update_log_forwarding(Bunnyx.t() | keyword(), String.t(), map()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def update_log_forwarding(client, config_id, config) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :put, "/mc/log/forwarding/#{config_id}", json: config) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Deletes a log forwarding configuration."
  @spec delete_log_forwarding(Bunnyx.t() | keyword(), String.t()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def delete_log_forwarding(client, config_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :delete, "/mc/log/forwarding/#{config_id}", []) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  defp to_list_params(opts) do
    mapping = %{per_page: "limit", next_cursor: "nextCursor"}

    opts
    |> Keyword.take([:per_page, :next_cursor])
    |> Map.new(fn {key, value} ->
      {Map.fetch!(mapping, key), value}
    end)
  end
end
