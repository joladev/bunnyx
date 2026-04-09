defmodule Bunnyx.Shield.Zone do
  @moduledoc """
  A Shield zone configuration. Maps camelCase API fields to snake_case Elixir fields.
  """

  @type t :: %__MODULE__{
          shield_zone_id: pos_integer() | nil,
          pull_zone_id: pos_integer() | nil,
          plan_type: integer() | nil,
          learning_mode: boolean() | nil,
          learning_mode_until: String.t() | nil,
          waf_enabled: boolean() | nil,
          waf_execution_mode: integer() | nil,
          waf_profile_id: integer() | nil,
          waf_disabled_rules: [String.t()] | nil,
          waf_log_only_rules: [String.t()] | nil,
          waf_request_header_logging_enabled: boolean() | nil,
          waf_realtime_threat_intelligence_enabled: boolean() | nil,
          rate_limit_rules_limit: integer() | nil,
          custom_waf_rules_limit: integer() | nil,
          ddos_shield_sensitivity: integer() | nil,
          ddos_execution_mode: integer() | nil,
          ddos_challenge_window: integer() | nil,
          block_vpn: boolean() | nil,
          block_tor: boolean() | nil,
          block_datacentre: boolean() | nil,
          whitelabel_response_pages: boolean() | nil
        }

  defstruct [
    :shield_zone_id,
    :pull_zone_id,
    :plan_type,
    :learning_mode,
    :learning_mode_until,
    :waf_enabled,
    :waf_execution_mode,
    :waf_profile_id,
    :waf_disabled_rules,
    :waf_log_only_rules,
    :waf_request_header_logging_enabled,
    :waf_realtime_threat_intelligence_enabled,
    :rate_limit_rules_limit,
    :custom_waf_rules_limit,
    :ddos_shield_sensitivity,
    :ddos_execution_mode,
    :ddos_challenge_window,
    :block_vpn,
    :block_tor,
    :block_datacentre,
    :whitelabel_response_pages
  ]

  @field_mapping %{
    "shieldZoneId" => :shield_zone_id,
    "pullZoneId" => :pull_zone_id,
    "planType" => :plan_type,
    "learningMode" => :learning_mode,
    "learningModeUntil" => :learning_mode_until,
    "wafEnabled" => :waf_enabled,
    "wafExecutionMode" => :waf_execution_mode,
    "wafProfileId" => :waf_profile_id,
    "wafDisabledRules" => :waf_disabled_rules,
    "wafLogOnlyRules" => :waf_log_only_rules,
    "wafRequestHeaderLoggingEnabled" => :waf_request_header_logging_enabled,
    "wafRealtimeThreatIntelligenceEnabled" => :waf_realtime_threat_intelligence_enabled,
    "rateLimitRulesLimit" => :rate_limit_rules_limit,
    "customWafRulesLimit" => :custom_waf_rules_limit,
    "dDoSShieldSensitivity" => :ddos_shield_sensitivity,
    "dDoSExecutionMode" => :ddos_execution_mode,
    "dDoSChallengeWindow" => :ddos_challenge_window,
    "blockVpn" => :block_vpn,
    "blockTor" => :block_tor,
    "blockDatacentre" => :block_datacentre,
    "whitelabelResponsePages" => :whitelabel_response_pages
  }

  @reverse_mapping Map.new(@field_mapping, fn {camel, atom} -> {atom, camel} end)

  @doc false
  @spec from_response(map()) :: t()
  def from_response(data) when is_map(data) do
    fields =
      for {camel, atom} <- @field_mapping, Map.has_key?(data, camel), into: %{} do
        {atom, data[camel]}
      end

    struct(__MODULE__, fields)
  end

  @doc false
  @spec to_request_body(Bunnyx.Params.attrs()) :: map()
  def to_request_body(attrs) do
    Bunnyx.Params.map_keys!(attrs, @reverse_mapping)
  end
end
