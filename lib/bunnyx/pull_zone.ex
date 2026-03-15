defmodule Bunnyx.PullZone do
  @moduledoc """
  Pull zones are bunny.net's CDN distribution points. Each pull zone pulls content
  from your origin server and caches it across their global edge network.

  Uses the main API client created with `Bunnyx.new/1`.

  ## Usage

      client = Bunnyx.new(api_key: "sk-...")

      {:ok, zone} = Bunnyx.PullZone.create(client,
        name: "my-zone",
        origin_url: "https://example.com"
      )

      {:ok, zone} = Bunnyx.PullZone.get(client, zone.id)
      {:ok, page} = Bunnyx.PullZone.list(client)
      {:ok, zone} = Bunnyx.PullZone.update(client, zone.id, cache_control_max_age_override: 3600)
      {:ok, nil} = Bunnyx.PullZone.delete(client, zone.id)
  """

  @type t :: %__MODULE__{
          id: pos_integer() | nil,
          name: String.t() | nil,
          origin_url: String.t() | nil,
          enabled: boolean() | nil,
          suspended: boolean() | nil,
          hostnames: [map()] | nil,
          storage_zone_id: integer() | nil,
          monthly_bandwidth_limit: integer() | nil,
          monthly_bandwidth_used: integer() | nil,
          cache_control_max_age_override: integer() | nil,
          ignore_query_strings: boolean() | nil,
          type: integer() | nil
        }

  defstruct [
    :id,
    :name,
    :origin_url,
    :enabled,
    :suspended,
    :hostnames,
    :storage_zone_id,
    :monthly_bandwidth_limit,
    :monthly_bandwidth_used,
    :cache_control_max_age_override,
    :ignore_query_strings,
    :type
  ]

  @field_mapping %{
    "Id" => :id,
    "Name" => :name,
    "OriginUrl" => :origin_url,
    "Enabled" => :enabled,
    "Suspended" => :suspended,
    "Hostnames" => :hostnames,
    "StorageZoneId" => :storage_zone_id,
    "MonthlyBandwidthLimit" => :monthly_bandwidth_limit,
    "MonthlyBandwidthUsed" => :monthly_bandwidth_used,
    "CacheControlMaxAgeOverride" => :cache_control_max_age_override,
    "IgnoreQueryStrings" => :ignore_query_strings,
    "Type" => :type
  }

  @reverse_mapping Map.new(@field_mapping, fn {pascal, atom} -> {atom, pascal} end)

  @doc """
  Lists pull zones.

  ## Options

    * `:page` — page number
    * `:per_page` — items per page
    * `:search` — search term

  """
  @spec list(Bunnyx.t() | keyword(), keyword()) ::
          {:ok,
           %{
             items: [t()],
             current_page: integer(),
             total_items: integer(),
             has_more_items: boolean()
           }}
          | {:error, Bunnyx.Error.t()}
  def list(client, opts \\ []) do
    client = Bunnyx.resolve(client)

    params =
      opts
      |> Keyword.take([:page, :per_page, :search])
      |> to_query_params()

    case Bunnyx.HTTP.request(client.req, :get, "/pullzone", params: params) do
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

  @doc "Fetches a pull zone by ID."
  @spec get(Bunnyx.t() | keyword(), pos_integer()) :: {:ok, t()} | {:error, Bunnyx.Error.t()}
  def get(client, id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/pullzone/#{id}", []) do
      {:ok, body} -> {:ok, from_response(body)}
      {:error, _} = error -> error
    end
  end

  @doc "Creates a pull zone with the given attributes."
  @spec create(Bunnyx.t() | keyword(), keyword()) :: {:ok, t()} | {:error, Bunnyx.Error.t()}
  def create(client, attrs) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/pullzone", json: to_request_body(attrs)) do
      {:ok, body} -> {:ok, from_response(body)}
      {:error, _} = error -> error
    end
  end

  @doc "Updates a pull zone."
  @spec update(Bunnyx.t() | keyword(), pos_integer(), keyword()) ::
          {:ok, t()} | {:error, Bunnyx.Error.t()}
  def update(client, id, attrs) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/pullzone/#{id}", json: to_request_body(attrs)) do
      {:ok, body} -> {:ok, from_response(body)}
      {:error, _} = error -> error
    end
  end

  @doc "Deletes a pull zone."
  @spec delete(Bunnyx.t() | keyword(), pos_integer()) :: {:ok, nil} | {:error, Bunnyx.Error.t()}
  def delete(client, id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :delete, "/pullzone/#{id}", []) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Adds a custom hostname to a pull zone."
  @spec add_hostname(Bunnyx.t() | keyword(), pos_integer(), String.t()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def add_hostname(client, id, hostname) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/pullzone/#{id}/addHostname",
           json: %{"Hostname" => hostname}
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Removes a custom hostname from a pull zone."
  @spec remove_hostname(Bunnyx.t() | keyword(), pos_integer(), String.t()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def remove_hostname(client, id, hostname) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :delete, "/pullzone/#{id}/removeHostname",
           json: %{"Hostname" => hostname}
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Adds an IP address to the pull zone's block list."
  @spec add_blocked_ip(Bunnyx.t() | keyword(), pos_integer(), String.t()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def add_blocked_ip(client, id, ip) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/pullzone/#{id}/addBlockedIp",
           json: %{"Value" => ip}
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Removes an IP address from the pull zone's block list."
  @spec remove_blocked_ip(Bunnyx.t() | keyword(), pos_integer(), String.t()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def remove_blocked_ip(client, id, ip) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/pullzone/#{id}/removeBlockedIp",
           json: %{"Value" => ip}
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Resets the token authentication security key for a pull zone."
  @spec reset_security_key(Bunnyx.t() | keyword(), pos_integer()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def reset_security_key(client, id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/pullzone/#{id}/resetSecurityKey", []) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Checks if a pull zone name is available."
  @spec check_availability(Bunnyx.t() | keyword(), String.t()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def check_availability(client, name) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/pullzone/checkavailability",
           json: %{"Name" => name}
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc """
  Returns optimizer statistics for a pull zone.

  ## Options

    * `:date_from` — start date (ISO 8601 string)
    * `:date_to` — end date (ISO 8601 string)
    * `:hourly` — group by hour instead of day

  """
  @spec optimizer_statistics(Bunnyx.t() | keyword(), pos_integer(), keyword()) ::
          {:ok,
           %{
             requests_optimized_chart: map(),
             average_compression_chart: map(),
             traffic_saved_chart: map(),
             average_processing_time_chart: map(),
             total_requests_optimized: number(),
             total_traffic_saved: number(),
             average_processing_time: number(),
             average_compression_ratio: number()
           }}
          | {:error, Bunnyx.Error.t()}
  def optimizer_statistics(client, id, opts \\ []) do
    client = Bunnyx.resolve(client)
    params = to_statistics_params(opts)

    case Bunnyx.HTTP.request(client.req, :get, "/pullzone/#{id}/optimizer/statistics",
           params: params
         ) do
      {:ok, body} ->
        {:ok,
         %{
           requests_optimized_chart: body["RequestsOptimizedChart"],
           average_compression_chart: body["AverageCompressionChart"],
           traffic_saved_chart: body["TrafficSavedChart"],
           average_processing_time_chart: body["AverageProcessingTimeChart"],
           total_requests_optimized: body["TotalRequestsOptimized"],
           total_traffic_saved: body["TotalTrafficSaved"],
           average_processing_time: body["AverageProcessingTime"],
           average_compression_ratio: body["AverageCompressionRatio"]
         }}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Returns SafeHop statistics for a pull zone.

  ## Options

    * `:date_from` — start date (ISO 8601 string)
    * `:date_to` — end date (ISO 8601 string)
    * `:hourly` — group by hour instead of day

  """
  @spec safehop_statistics(Bunnyx.t() | keyword(), pos_integer(), keyword()) ::
          {:ok,
           %{
             requests_retried_chart: map(),
             requests_saved_chart: map(),
             total_requests_retried: number(),
             total_requests_saved: number()
           }}
          | {:error, Bunnyx.Error.t()}
  def safehop_statistics(client, id, opts \\ []) do
    client = Bunnyx.resolve(client)
    params = to_statistics_params(opts)

    case Bunnyx.HTTP.request(client.req, :get, "/pullzone/#{id}/safehop/statistics",
           params: params
         ) do
      {:ok, body} ->
        {:ok,
         %{
           requests_retried_chart: body["RequestsRetriedChart"],
           requests_saved_chart: body["RequestsSavedChart"],
           total_requests_retried: body["TotalRequestsRetried"],
           total_requests_saved: body["TotalRequestsSaved"]
         }}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Returns origin shield queue statistics for a pull zone.

  ## Options

    * `:date_from` — start date (ISO 8601 string)
    * `:date_to` — end date (ISO 8601 string)
    * `:hourly` — group by hour instead of day

  """
  @spec origin_shield_statistics(Bunnyx.t() | keyword(), pos_integer(), keyword()) ::
          {:ok, %{concurrent_requests_chart: map(), queued_requests_chart: map()}}
          | {:error, Bunnyx.Error.t()}
  def origin_shield_statistics(client, id, opts \\ []) do
    client = Bunnyx.resolve(client)
    params = to_statistics_params(opts)

    case Bunnyx.HTTP.request(client.req, :get, "/pullzone/#{id}/originshield/queuestatistics",
           params: params
         ) do
      {:ok, body} ->
        {:ok,
         %{
           concurrent_requests_chart: body["ConcurrentRequestsChart"],
           queued_requests_chart: body["QueuedRequestsChart"]
         }}

      {:error, _} = error ->
        error
    end
  end

  @edge_rule_mapping %{
    guid: "Guid",
    action_type: "ActionType",
    action_parameter_1: "ActionParameter1",
    action_parameter_2: "ActionParameter2",
    action_parameter_3: "ActionParameter3",
    triggers: "Triggers",
    extra_actions: "ExtraActions",
    trigger_matching_type: "TriggerMatchingType",
    description: "Description",
    enabled: "Enabled",
    order_index: "OrderIndex",
    read_only: "ReadOnly"
  }

  @doc """
  Adds or updates an edge rule on a pull zone.

  ## Attributes

    * `:action_type` — rule action type (integer)
    * `:action_parameter_1` — action parameter 1
    * `:action_parameter_2` — action parameter 2
    * `:action_parameter_3` — action parameter 3
    * `:triggers` — list of trigger maps (PascalCase keys)
    * `:extra_actions` — list of extra action maps (PascalCase keys)
    * `:trigger_matching_type` — 0 = match any, 1 = match all, 2 = match none
    * `:description` — rule description
    * `:enabled` — whether the rule is active
    * `:guid` — rule GUID (required for updates)

  """
  @spec add_or_update_edge_rule(Bunnyx.t() | keyword(), pos_integer(), keyword()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def add_or_update_edge_rule(client, id, attrs) do
    client = Bunnyx.resolve(client)

    json =
      Map.new(attrs, fn {key, value} ->
        {Map.fetch!(@edge_rule_mapping, key), value}
      end)

    case Bunnyx.HTTP.request(client.req, :post, "/pullzone/#{id}/edgerules/addOrUpdate",
           json: json
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Deletes an edge rule from a pull zone."
  @spec delete_edge_rule(Bunnyx.t() | keyword(), pos_integer(), String.t()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def delete_edge_rule(client, id, edge_rule_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(
           client.req,
           :delete,
           "/pullzone/#{id}/edgerules/#{edge_rule_id}",
           []
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Enables or disables an edge rule on a pull zone."
  @spec set_edge_rule_enabled(Bunnyx.t() | keyword(), pos_integer(), String.t(), boolean()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def set_edge_rule_enabled(client, id, edge_rule_id, enabled) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(
           client.req,
           :post,
           "/pullzone/#{id}/edgerules/#{edge_rule_id}/setEdgeRuleEnabled",
           json: %{"Id" => edge_rule_id, "Value" => enabled}
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Provisions a free Let's Encrypt certificate for a hostname."
  @spec load_free_certificate(Bunnyx.t() | keyword(), String.t()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def load_free_certificate(client, hostname) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/pullzone/loadFreeCertificate",
           params: %{"hostname" => hostname}
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Updates the SSL private key type for a hostname on a pull zone (0 = ECDSA, 1 = RSA)."
  @spec update_private_key_type(Bunnyx.t() | keyword(), pos_integer(), String.t(), integer()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def update_private_key_type(client, id, hostname, key_type) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/pullzone/#{id}/updatePrivateKeyType",
           json: %{"Hostname" => hostname, "KeyType" => key_type}
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Enables or disables forced SSL for a hostname on a pull zone."
  @spec set_force_ssl(Bunnyx.t() | keyword(), pos_integer(), String.t(), boolean()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def set_force_ssl(client, id, hostname, force_ssl) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/pullzone/#{id}/setForceSSL",
           json: %{"Hostname" => hostname, "ForceSSL" => force_ssl}
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Uploads a custom SSL certificate for a hostname on a pull zone."
  @spec add_certificate(Bunnyx.t() | keyword(), pos_integer(), String.t(), String.t(), String.t()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def add_certificate(client, id, hostname, certificate, certificate_key) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/pullzone/#{id}/addCertificate",
           json: %{
             "Hostname" => hostname,
             "Certificate" => certificate,
             "CertificateKey" => certificate_key
           }
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Removes an SSL certificate from a hostname on a pull zone."
  @spec remove_certificate(Bunnyx.t() | keyword(), pos_integer(), String.t()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def remove_certificate(client, id, hostname) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :delete, "/pullzone/#{id}/removeCertificate",
           json: %{"Hostname" => hostname}
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Adds a hostname to the pull zone's allowed referrer list."
  @spec add_allowed_referrer(Bunnyx.t() | keyword(), pos_integer(), String.t()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def add_allowed_referrer(client, id, hostname) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/pullzone/#{id}/addAllowedReferrer",
           json: %{"Hostname" => hostname}
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Removes a hostname from the pull zone's allowed referrer list."
  @spec remove_allowed_referrer(Bunnyx.t() | keyword(), pos_integer(), String.t()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def remove_allowed_referrer(client, id, hostname) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/pullzone/#{id}/removeAllowedReferrer",
           json: %{"Hostname" => hostname}
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Adds a hostname to the pull zone's blocked referrer list."
  @spec add_blocked_referrer(Bunnyx.t() | keyword(), pos_integer(), String.t()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def add_blocked_referrer(client, id, hostname) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/pullzone/#{id}/addBlockedReferrer",
           json: %{"Hostname" => hostname}
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Removes a hostname from the pull zone's blocked referrer list."
  @spec remove_blocked_referrer(Bunnyx.t() | keyword(), pos_integer(), String.t()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def remove_blocked_referrer(client, id, hostname) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/pullzone/#{id}/removeBlockedReferrer",
           json: %{"Hostname" => hostname}
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  defp from_response(data) when is_map(data) do
    fields =
      for {pascal, atom} <- @field_mapping, Map.has_key?(data, pascal), into: %{} do
        {atom, data[pascal]}
      end

    struct(__MODULE__, fields)
  end

  defp to_request_body(attrs) do
    Map.new(attrs, fn {key, value} ->
      pascal = Map.fetch!(@reverse_mapping, key)
      {pascal, value}
    end)
  end

  defp to_statistics_params(opts) do
    mapping = %{date_from: "dateFrom", date_to: "dateTo", hourly: "hourly"}

    opts
    |> Keyword.take([:date_from, :date_to, :hourly])
    |> Map.new(fn {key, value} ->
      {Map.fetch!(mapping, key), value}
    end)
  end

  defp to_query_params(opts) do
    mapping = %{page: "page", per_page: "perPage", search: "search"}

    Map.new(opts, fn {key, value} ->
      {Map.fetch!(mapping, key), value}
    end)
  end
end
