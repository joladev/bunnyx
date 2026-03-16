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

  defp to_page_params(opts) do
    mapping = %{page: "page", page_size: "pageSize"}

    opts
    |> Keyword.take([:page, :page_size])
    |> Map.new(fn {key, value} ->
      {Map.fetch!(mapping, key), value}
    end)
  end
end
