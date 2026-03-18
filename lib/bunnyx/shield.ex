defmodule Bunnyx.Shield do
  @moduledoc """
  Bunny Shield — WAF, rate limiting, bot detection, and access control for
  pull zones. A Shield zone wraps a pull zone with security configuration.

  Uses the main API client created with `Bunnyx.new/1`. The Shield API lives
  under `/shield/...` on the same base URL.

  ## Usage

      client = Bunnyx.new(api_key: "sk-...")

      {:ok, zone} = Bunnyx.Shield.create(client, 12345)
      {:ok, zones} = Bunnyx.Shield.list(client)
      {:ok, zone} = Bunnyx.Shield.get(client, zone.shield_zone_id)
      {:ok, zone} = Bunnyx.Shield.get_by_pull_zone(client, 12345)
      {:ok, zone} = Bunnyx.Shield.update(client, zone.shield_zone_id, waf_enabled: true)
  """

  alias Bunnyx.Shield.Zone

  @doc "Creates a Shield zone for a pull zone."
  @spec create(Bunnyx.t() | keyword(), pos_integer(), keyword()) ::
          {:ok, Zone.t()} | {:error, Bunnyx.Error.t()}
  def create(client, pull_zone_id, opts \\ []) do
    client = Bunnyx.resolve(client)

    json = %{"pullZoneId" => pull_zone_id}

    json =
      if opts != [] do
        Map.put(json, "shieldZone", Zone.to_request_body(opts))
      else
        json
      end

    case Bunnyx.HTTP.request(client.req, :post, "/shield/shield-zone", json: json) do
      {:ok, body} -> {:ok, unwrap_data(body)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Lists all Shield zones.

  ## Options

    * `:page` — page number
    * `:page_size` — items per page

  """
  @spec list(Bunnyx.t() | keyword(), keyword()) ::
          {:ok, %{items: [Zone.t()], page: map()}} | {:error, Bunnyx.Error.t()}
  def list(client, opts \\ []) do
    client = Bunnyx.resolve(client)
    params = to_page_params(opts)

    case Bunnyx.HTTP.request(client.req, :get, "/shield/shield-zones", params: params) do
      {:ok, body} ->
        {:ok, unwrap_list(body)}

      {:error, _} = error ->
        error
    end
  end

  @doc "Lists active Shield zones with pull zone mapping."
  @spec list_active(Bunnyx.t() | keyword(), keyword()) ::
          {:ok, %{items: [Zone.t()], page: map()}} | {:error, Bunnyx.Error.t()}
  def list_active(client, opts \\ []) do
    client = Bunnyx.resolve(client)
    params = to_page_params(opts)

    case Bunnyx.HTTP.request(client.req, :get, "/shield/shield-zones/active", params: params) do
      {:ok, body} ->
        {:ok, unwrap_list(body)}

      {:error, _} = error ->
        error
    end
  end

  @doc "Fetches a Shield zone by ID."
  @spec get(Bunnyx.t() | keyword(), pos_integer()) ::
          {:ok, Zone.t()} | {:error, Bunnyx.Error.t()}
  def get(client, shield_zone_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/shield/shield-zone/#{shield_zone_id}", []) do
      {:ok, body} -> {:ok, unwrap_data(body)}
      {:error, _} = error -> error
    end
  end

  @doc "Fetches a Shield zone by its associated pull zone ID."
  @spec get_by_pull_zone(Bunnyx.t() | keyword(), pos_integer()) ::
          {:ok, Zone.t()} | {:error, Bunnyx.Error.t()}
  def get_by_pull_zone(client, pull_zone_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(
           client.req,
           :get,
           "/shield/shield-zone/pull-zone/#{pull_zone_id}",
           []
         ) do
      {:ok, body} -> {:ok, unwrap_data(body)}
      {:error, _} = error -> error
    end
  end

  @doc "Updates a Shield zone's configuration."
  @spec update(Bunnyx.t() | keyword(), pos_integer(), keyword()) ::
          {:ok, Zone.t()} | {:error, Bunnyx.Error.t()}
  def update(client, shield_zone_id, attrs) do
    client = Bunnyx.resolve(client)

    json = %{
      "shieldZoneId" => shield_zone_id,
      "shieldZone" => Zone.to_request_body(attrs)
    }

    case Bunnyx.HTTP.request(client.req, :patch, "/shield/shield-zone", json: json) do
      {:ok, body} -> {:ok, unwrap_data(body)}
      {:error, _} = error -> error
    end
  end

  # -- Promotions --

  @doc "Gets the current promotion state for your account."
  @spec get_promotions(Bunnyx.t() | keyword()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def get_promotions(client) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/shield/promotions", []) do
      {:ok, body} -> {:ok, unwrap_raw_data(body)}
      {:error, _} = error -> error
    end
  end

  # -- API Guardian --

  @doc "Gets the API Guardian configuration and endpoints for a Shield zone."
  @spec get_api_guardian(Bunnyx.t() | keyword(), pos_integer()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def get_api_guardian(client, shield_zone_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(
           client.req,
           :get,
           "/shield/shield-zone/#{shield_zone_id}/api-guardian",
           []
         ) do
      {:ok, body} -> {:ok, unwrap_raw_data(body)}
      {:error, _} = error -> error
    end
  end

  @doc "Updates an API Guardian endpoint configuration."
  @spec update_api_guardian_endpoint(
          Bunnyx.t() | keyword(),
          pos_integer(),
          pos_integer(),
          keyword()
        ) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def update_api_guardian_endpoint(client, shield_zone_id, endpoint_id, attrs) do
    client = Bunnyx.resolve(client)

    json = to_api_guardian_endpoint_body(attrs)

    case Bunnyx.HTTP.request(
           client.req,
           :patch,
           "/shield/shield-zone/#{shield_zone_id}/api-guardian/endpoint/#{endpoint_id}",
           json: json
         ) do
      {:ok, body} -> {:ok, unwrap_raw_data(body)}
      {:error, _} = error -> error
    end
  end

  @doc "Uploads an OpenAPI specification to API Guardian."
  @spec upload_openapi_spec(Bunnyx.t() | keyword(), pos_integer(), String.t(), keyword()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def upload_openapi_spec(client, shield_zone_id, content, opts \\ []) do
    client = Bunnyx.resolve(client)

    json = %{"content" => content}

    json =
      case Keyword.fetch(opts, :enforce_authorisation_validation) do
        {:ok, val} -> Map.put(json, "enforceAuthorisationValidation", val)
        :error -> json
      end

    case Bunnyx.HTTP.request(
           client.req,
           :post,
           "/shield/shield-zone/#{shield_zone_id}/api-guardian",
           json: json
         ) do
      {:ok, body} -> {:ok, unwrap_raw_data(body)}
      {:error, _} = error -> error
    end
  end

  @doc "Updates an existing OpenAPI specification on API Guardian."
  @spec update_openapi_spec(Bunnyx.t() | keyword(), pos_integer(), String.t(), keyword()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def update_openapi_spec(client, shield_zone_id, content, opts \\ []) do
    client = Bunnyx.resolve(client)

    json = %{"content" => content}

    json =
      case Keyword.fetch(opts, :enforce_authorisation_validation) do
        {:ok, val} -> Map.put(json, "enforceAuthorisationValidation", val)
        :error -> json
      end

    case Bunnyx.HTTP.request(
           client.req,
           :patch,
           "/shield/shield-zone/#{shield_zone_id}/api-guardian",
           json: json
         ) do
      {:ok, body} -> {:ok, unwrap_raw_data(body)}
      {:error, _} = error -> error
    end
  end

  # -- WAF --

  @waf_rule_mapping %{
    rule_name: "ruleName",
    rule_description: "ruleDescription",
    rule_configuration: "ruleConfiguration"
  }

  @doc "Lists all WAF rules available for a Shield zone."
  @spec list_waf_rules(Bunnyx.t() | keyword(), pos_integer()) ::
          {:ok, list()} | {:error, Bunnyx.Error.t()}
  def list_waf_rules(client, shield_zone_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/shield/waf/rules/#{shield_zone_id}", []) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Lists custom WAF rules for a Shield zone."
  @spec list_custom_waf_rules(Bunnyx.t() | keyword(), pos_integer()) ::
          {:ok, %{items: [map()], page: map()}} | {:error, Bunnyx.Error.t()}
  def list_custom_waf_rules(client, shield_zone_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(
           client.req,
           :get,
           "/shield/waf/custom-rules/#{shield_zone_id}",
           []
         ) do
      {:ok, body} ->
        {:ok, %{items: Map.get(body, "data", []), page: body["page"]}}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Creates a custom WAF rule.

  ## Attributes

    * `:shield_zone_id` (required) — Shield zone ID
    * `:rule_name` — rule name
    * `:rule_description` — rule description
    * `:rule_configuration` — rule config map (passed through as-is)

  """
  @spec create_custom_waf_rule(Bunnyx.t() | keyword(), keyword()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def create_custom_waf_rule(client, attrs) do
    client = Bunnyx.resolve(client)

    json =
      Map.merge(
        %{"shieldZoneId" => Keyword.fetch!(attrs, :shield_zone_id)},
        to_waf_body(Keyword.delete(attrs, :shield_zone_id))
      )

    case Bunnyx.HTTP.request(client.req, :post, "/shield/waf/custom-rule", json: json) do
      {:ok, body} -> {:ok, unwrap_raw_data(body)}
      {:error, _} = error -> error
    end
  end

  @doc "Gets a specific custom WAF rule by ID."
  @spec get_custom_waf_rule(Bunnyx.t() | keyword(), pos_integer()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def get_custom_waf_rule(client, rule_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/shield/waf/custom-rule/#{rule_id}", []) do
      {:ok, body} -> {:ok, unwrap_raw_data(body)}
      {:error, _} = error -> error
    end
  end

  @doc "Updates a custom WAF rule."
  @spec update_custom_waf_rule(Bunnyx.t() | keyword(), pos_integer(), keyword()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def update_custom_waf_rule(client, rule_id, attrs) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :patch, "/shield/waf/custom-rule/#{rule_id}",
           json: to_waf_body(attrs)
         ) do
      {:ok, body} -> {:ok, unwrap_raw_data(body)}
      {:error, _} = error -> error
    end
  end

  @doc "Deletes a custom WAF rule."
  @spec delete_custom_waf_rule(Bunnyx.t() | keyword(), pos_integer()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def delete_custom_waf_rule(client, rule_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :delete, "/shield/waf/custom-rule/#{rule_id}", []) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Lists available WAF profiles."
  @spec list_waf_profiles(Bunnyx.t() | keyword()) ::
          {:ok, [map()]} | {:error, Bunnyx.Error.t()}
  def list_waf_profiles(client) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/shield/waf/profiles", []) do
      {:ok, body} -> {:ok, Map.get(body, "data", [])}
      {:error, _} = error -> error
    end
  end

  @doc "Returns the default WAF engine configuration."
  @spec get_default_waf_config(Bunnyx.t() | keyword()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def get_default_waf_config(client) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/shield/waf/engine-config/default", []) do
      {:ok, body} -> {:ok, unwrap_raw_data(body)}
      {:error, _} = error -> error
    end
  end

  @doc "Lists WAF rules segmented by subscription plan."
  @spec list_waf_rules_by_plan(Bunnyx.t() | keyword()) ::
          {:ok, list()} | {:error, Bunnyx.Error.t()}
  def list_waf_rules_by_plan(client) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/shield/waf/rules/plan", []) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Lists all triggered WAF rules for a Shield zone."
  @spec list_triggered_waf_rules(Bunnyx.t() | keyword(), pos_integer()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def list_triggered_waf_rules(client, shield_zone_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(
           client.req,
           :get,
           "/shield/waf/rules/review-triggered/#{shield_zone_id}",
           []
         ) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Updates the action for a triggered WAF rule."
  @spec update_triggered_waf_rule(Bunnyx.t() | keyword(), pos_integer(), String.t(), integer()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def update_triggered_waf_rule(client, shield_zone_id, rule_id, action) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(
           client.req,
           :post,
           "/shield/waf/rules/review-triggered/#{shield_zone_id}",
           json: %{"ruleId" => rule_id, "action" => action}
         ) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Gets an AI recommendation for a triggered WAF rule."
  @spec get_waf_ai_recommendation(Bunnyx.t() | keyword(), pos_integer(), String.t()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def get_waf_ai_recommendation(client, shield_zone_id, rule_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(
           client.req,
           :get,
           "/shield/waf/rules/review-triggered/ai-recommendation/#{shield_zone_id}/#{rule_id}",
           []
         ) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Lists all WAF enum mappings."
  @spec list_waf_enums(Bunnyx.t() | keyword()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def list_waf_enums(client) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/shield/waf/enums", []) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  # -- Metrics --

  @doc "Returns a metrics overview for a Shield zone."
  @spec metrics_overview(Bunnyx.t() | keyword(), pos_integer()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def metrics_overview(client, shield_zone_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(
           client.req,
           :get,
           "/shield/metrics/overview/#{shield_zone_id}",
           []
         ) do
      {:ok, body} -> {:ok, unwrap_raw_data(body)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Returns detailed metrics for a Shield zone within a time range.

  ## Options

    * `:start_date` — start date (ISO 8601 string)
    * `:end_date` — end date (ISO 8601 string)
    * `:resolution` — time resolution (0-6)

  """
  @spec metrics_detailed(Bunnyx.t() | keyword(), pos_integer(), keyword()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def metrics_detailed(client, shield_zone_id, opts \\ []) do
    client = Bunnyx.resolve(client)
    params = to_metrics_params(opts)

    case Bunnyx.HTTP.request(
           client.req,
           :get,
           "/shield/metrics/overview/#{shield_zone_id}/detailed",
           params: params
         ) do
      {:ok, body} -> {:ok, unwrap_raw_data(body)}
      {:error, _} = error -> error
    end
  end

  @doc "Returns aggregated rate limit metrics for a Shield zone."
  @spec metrics_rate_limits(Bunnyx.t() | keyword(), pos_integer()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def metrics_rate_limits(client, shield_zone_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(
           client.req,
           :get,
           "/shield/metrics/rate-limits/#{shield_zone_id}",
           []
         ) do
      {:ok, body} -> {:ok, unwrap_raw_data(body)}
      {:error, _} = error -> error
    end
  end

  @doc "Returns detailed metrics for a specific rate limit."
  @spec metrics_rate_limit(Bunnyx.t() | keyword(), pos_integer()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def metrics_rate_limit(client, rate_limit_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(
           client.req,
           :get,
           "/shield/metrics/rate-limit/#{rate_limit_id}",
           []
         ) do
      {:ok, body} -> {:ok, unwrap_raw_data(body)}
      {:error, _} = error -> error
    end
  end

  @doc "Returns bot detection metrics for a Shield zone."
  @spec metrics_bot_detection(Bunnyx.t() | keyword(), pos_integer()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def metrics_bot_detection(client, shield_zone_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(
           client.req,
           :get,
           "/shield/metrics/shield-zone/#{shield_zone_id}/bot-detection",
           []
         ) do
      {:ok, body} -> {:ok, unwrap_raw_data(body)}
      {:error, _} = error -> error
    end
  end

  @doc "Returns metrics for a specific WAF rule within a Shield zone."
  @spec metrics_waf_rule(Bunnyx.t() | keyword(), pos_integer(), String.t()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def metrics_waf_rule(client, shield_zone_id, rule_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(
           client.req,
           :get,
           "/shield/metrics/shield-zone/#{shield_zone_id}/waf-rule/#{rule_id}",
           []
         ) do
      {:ok, body} -> {:ok, unwrap_raw_data(body)}
      {:error, _} = error -> error
    end
  end

  @doc "Returns upload scanning metrics for a Shield zone."
  @spec metrics_upload_scanning(Bunnyx.t() | keyword(), pos_integer()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def metrics_upload_scanning(client, shield_zone_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(
           client.req,
           :get,
           "/shield/metrics/shield-zone/#{shield_zone_id}/upload-scanning",
           []
         ) do
      {:ok, body} -> {:ok, unwrap_raw_data(body)}
      {:error, _} = error -> error
    end
  end

  # -- Event Logs --

  @doc """
  Returns security event logs for a Shield zone on a given date.

  The date can be a `Date` struct or a string in `"MM-dd-yyyy"` format.
  Pass a continuation token for pagination.
  """
  @spec event_logs(Bunnyx.t() | keyword(), pos_integer(), Date.t() | String.t(), String.t()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def event_logs(client, shield_zone_id, date, continuation_token \\ "") do
    client = Bunnyx.resolve(client)
    date_str = format_date(date)

    path = "/shield/event-logs/#{shield_zone_id}/#{date_str}/#{continuation_token}"

    case Bunnyx.HTTP.request(client.req, :get, path, []) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  # -- Bot Detection --

  @doc "Gets the bot detection configuration for a Shield zone."
  @spec get_bot_detection(Bunnyx.t() | keyword(), pos_integer()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def get_bot_detection(client, shield_zone_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(
           client.req,
           :get,
           "/shield/shield-zone/#{shield_zone_id}/bot-detection",
           []
         ) do
      {:ok, body} -> {:ok, unwrap_raw_data(body)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Updates the bot detection configuration for a Shield zone.

  Accepts a map with the full config structure (passed through as JSON).
  """
  @spec update_bot_detection(Bunnyx.t() | keyword(), pos_integer(), map()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def update_bot_detection(client, shield_zone_id, config) do
    client = Bunnyx.resolve(client)

    json = Map.put(config, "shieldZoneId", shield_zone_id)

    case Bunnyx.HTTP.request(
           client.req,
           :patch,
           "/shield/shield-zone/#{shield_zone_id}/bot-detection",
           json: json
         ) do
      {:ok, body} -> {:ok, unwrap_raw_data(body)}
      {:error, _} = error -> error
    end
  end

  # -- Upload Scanning --

  @doc "Gets the upload scanning configuration for a Shield zone."
  @spec get_upload_scanning(Bunnyx.t() | keyword(), pos_integer()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def get_upload_scanning(client, shield_zone_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(
           client.req,
           :get,
           "/shield/shield-zone/#{shield_zone_id}/upload-scanning",
           []
         ) do
      {:ok, body} -> {:ok, unwrap_raw_data(body)}
      {:error, _} = error -> error
    end
  end

  @doc "Updates the upload scanning configuration for a Shield zone."
  @spec update_upload_scanning(Bunnyx.t() | keyword(), pos_integer(), map()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def update_upload_scanning(client, shield_zone_id, config) do
    client = Bunnyx.resolve(client)

    json = Map.put(config, "shieldZoneId", shield_zone_id)

    case Bunnyx.HTTP.request(
           client.req,
           :patch,
           "/shield/shield-zone/#{shield_zone_id}/upload-scanning",
           json: json
         ) do
      {:ok, body} -> {:ok, unwrap_raw_data(body)}
      {:error, _} = error -> error
    end
  end

  # -- DDoS --

  @doc "Lists all DDoS enum mappings."
  @spec list_ddos_enums(Bunnyx.t() | keyword()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def list_ddos_enums(client) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/shield/ddos/enums", []) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  # -- Rate Limiting --

  @rate_limit_mapping %{
    shield_zone_id: "shieldZoneId",
    rule_name: "ruleName",
    rule_description: "ruleDescription",
    rule_configuration: "ruleConfiguration"
  }

  @doc "Lists rate limits for a Shield zone."
  @spec list_rate_limits(Bunnyx.t() | keyword(), pos_integer()) ::
          {:ok, %{items: [map()], page: map()}} | {:error, Bunnyx.Error.t()}
  def list_rate_limits(client, shield_zone_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/shield/rate-limits/#{shield_zone_id}", []) do
      {:ok, body} -> {:ok, %{items: Map.get(body, "data", []), page: body["page"]}}
      {:error, _} = error -> error
    end
  end

  @doc "Gets an individual rate limit."
  @spec get_rate_limit(Bunnyx.t() | keyword(), pos_integer(), pos_integer()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def get_rate_limit(client, shield_zone_id, rate_limit_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(
           client.req,
           :get,
           "/shield/rate-limit/#{shield_zone_id}/#{rate_limit_id}",
           []
         ) do
      {:ok, body} -> {:ok, unwrap_raw_data(body)}
      {:error, _} = error -> error
    end
  end

  @doc "Creates a rate limit for a Shield zone."
  @spec create_rate_limit(Bunnyx.t() | keyword(), keyword()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def create_rate_limit(client, attrs) do
    client = Bunnyx.resolve(client)

    json =
      Map.new(attrs, fn {key, value} ->
        {Map.fetch!(@rate_limit_mapping, key), value}
      end)

    case Bunnyx.HTTP.request(client.req, :post, "/shield/rate-limit", json: json) do
      {:ok, body} -> {:ok, unwrap_raw_data(body)}
      {:error, _} = error -> error
    end
  end

  @doc "Updates a rate limit."
  @spec update_rate_limit(Bunnyx.t() | keyword(), pos_integer(), keyword()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def update_rate_limit(client, rate_limit_id, attrs) do
    client = Bunnyx.resolve(client)

    json =
      Map.new(attrs, fn {key, value} ->
        {Map.fetch!(@rate_limit_mapping, key), value}
      end)

    case Bunnyx.HTTP.request(client.req, :patch, "/shield/rate-limit/#{rate_limit_id}",
           json: json
         ) do
      {:ok, body} -> {:ok, unwrap_raw_data(body)}
      {:error, _} = error -> error
    end
  end

  @doc "Deletes a rate limit."
  @spec delete_rate_limit(Bunnyx.t() | keyword(), pos_integer()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def delete_rate_limit(client, rate_limit_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :delete, "/shield/rate-limit/#{rate_limit_id}", []) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  # -- Access Lists --

  @doc "Lists all access lists for a Shield zone."
  @spec list_access_lists(Bunnyx.t() | keyword(), pos_integer()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def list_access_lists(client, shield_zone_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(
           client.req,
           :get,
           "/shield/shield-zone/#{shield_zone_id}/access-lists",
           []
         ) do
      {:ok, body} -> {:ok, unwrap_raw_data(body)}
      {:error, _} = error -> error
    end
  end

  @doc "Gets a specific custom access list."
  @spec get_access_list(Bunnyx.t() | keyword(), pos_integer(), pos_integer()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def get_access_list(client, shield_zone_id, access_list_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(
           client.req,
           :get,
           "/shield/shield-zone/#{shield_zone_id}/access-lists/#{access_list_id}",
           []
         ) do
      {:ok, body} -> {:ok, unwrap_raw_data(body)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Creates a custom access list.

  ## Attributes

    * `:name` (required) — display name
    * `:type` (required) — access list type (integer enum)
    * `:content` (required) — entries separated by newlines
    * `:description` — optional description
    * `:checksum` — SHA-256 checksum for integrity

  """
  @spec create_access_list(Bunnyx.t() | keyword(), pos_integer(), keyword()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def create_access_list(client, shield_zone_id, attrs) do
    client = Bunnyx.resolve(client)

    json = to_access_list_body(attrs)

    case Bunnyx.HTTP.request(
           client.req,
           :post,
           "/shield/shield-zone/#{shield_zone_id}/access-lists",
           json: json
         ) do
      {:ok, body} -> {:ok, unwrap_raw_data(body)}
      {:error, _} = error -> error
    end
  end

  @doc "Updates a custom access list."
  @spec update_access_list(Bunnyx.t() | keyword(), pos_integer(), pos_integer(), keyword()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def update_access_list(client, shield_zone_id, access_list_id, attrs) do
    client = Bunnyx.resolve(client)

    json = to_access_list_body(attrs)

    case Bunnyx.HTTP.request(
           client.req,
           :put,
           "/shield/shield-zone/#{shield_zone_id}/access-lists/#{access_list_id}",
           json: json
         ) do
      {:ok, body} -> {:ok, unwrap_raw_data(body)}
      {:error, _} = error -> error
    end
  end

  @doc "Deletes a custom access list."
  @spec delete_access_list(Bunnyx.t() | keyword(), pos_integer(), pos_integer()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def delete_access_list(client, shield_zone_id, access_list_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(
           client.req,
           :delete,
           "/shield/shield-zone/#{shield_zone_id}/access-lists/#{access_list_id}",
           []
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Updates access list configuration (enable/disable and action)."
  @spec update_access_list_config(
          Bunnyx.t() | keyword(),
          pos_integer(),
          pos_integer(),
          keyword()
        ) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def update_access_list_config(client, shield_zone_id, config_id, attrs) do
    client = Bunnyx.resolve(client)

    json = to_access_list_config_body(attrs)

    case Bunnyx.HTTP.request(
           client.req,
           :patch,
           "/shield/shield-zone/#{shield_zone_id}/access-lists/configurations/#{config_id}",
           json: json
         ) do
      {:ok, body} -> {:ok, unwrap_raw_data(body)}
      {:error, _} = error -> error
    end
  end

  @doc "Lists access list enum types and their values."
  @spec list_access_list_enums(Bunnyx.t() | keyword(), pos_integer()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def list_access_list_enums(client, shield_zone_id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(
           client.req,
           :get,
           "/shield/shield-zone/#{shield_zone_id}/access-lists/enums",
           []
         ) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  defp unwrap_data(%{"data" => data}) when is_map(data), do: Zone.from_response(data)
  defp unwrap_data(body) when is_map(body), do: Zone.from_response(body)

  defp unwrap_list(body) do
    items =
      body
      |> Map.get("data", [])
      |> Enum.map(&Zone.from_response/1)

    %{items: items, page: body["page"]}
  end

  defp unwrap_raw_data(%{"data" => data}), do: data
  defp unwrap_raw_data(body), do: body

  defp to_waf_body(attrs) do
    Map.new(attrs, fn {key, value} ->
      {Map.fetch!(@waf_rule_mapping, key), value}
    end)
  end

  @access_list_mapping %{
    name: "name",
    type: "type",
    content: "content",
    description: "description",
    checksum: "checksum"
  }

  defp to_access_list_body(attrs) do
    Map.new(attrs, fn {key, value} ->
      {Map.fetch!(@access_list_mapping, key), value}
    end)
  end

  @access_list_config_mapping %{is_enabled: "isEnabled", action: "action"}

  defp to_access_list_config_body(attrs) do
    Map.new(attrs, fn {key, value} ->
      {Map.fetch!(@access_list_config_mapping, key), value}
    end)
  end

  @api_guardian_endpoint_mapping %{
    enabled: "enabled",
    validate_request_body_schema: "validateRequestBodySchema",
    validate_response_body_schema: "validateResponseBodySchema",
    validate_authorization: "validateAuthorization"
  }

  defp to_api_guardian_endpoint_body(attrs) do
    Map.new(attrs, fn {key, value} ->
      {Map.fetch!(@api_guardian_endpoint_mapping, key), value}
    end)
  end

  defp to_metrics_params(opts) do
    mapping = %{start_date: "StartDate", end_date: "EndDate", resolution: "Resolution"}

    opts
    |> Keyword.take([:start_date, :end_date, :resolution])
    |> Map.new(fn {key, value} ->
      {Map.fetch!(mapping, key), value}
    end)
  end

  defp format_date(%Date{} = date), do: Calendar.strftime(date, "%m-%d-%Y")
  defp format_date(date) when is_binary(date), do: date

  defp to_page_params(opts) do
    mapping = %{page: "page", page_size: "pageSize"}

    opts
    |> Keyword.take([:page, :page_size])
    |> Map.new(fn {key, value} ->
      {Map.fetch!(mapping, key), value}
    end)
  end
end
