defmodule Bunnyx.ShieldTest do
  use ExUnit.Case, async: true
  use Mimic

  setup do
    %{client: Bunnyx.new(api_key: "sk-test")}
  end

  describe "create/3" do
    test "sends pull zone ID and returns parsed zone", %{client: client} do
      response = Bunnyx.Factory.shield_zone_wrapped_response()

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/shield/shield-zone", opts ->
        assert opts[:json] == %{"pullZoneId" => 12_345}
        {:ok, response}
      end)

      assert {:ok, %Bunnyx.Shield.Zone{shield_zone_id: 100_001, pull_zone_id: 12_345}} =
               Bunnyx.Shield.create(client, 12_345)
    end

    test "passes shield zone options", %{client: client} do
      response = Bunnyx.Factory.shield_zone_wrapped_response(%{"wafEnabled" => true})

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/shield/shield-zone", opts ->
        assert opts[:json]["pullZoneId"] == 12_345
        assert opts[:json]["shieldZone"]["wafEnabled"] == true
        {:ok, response}
      end)

      assert {:ok, %Bunnyx.Shield.Zone{}} =
               Bunnyx.Shield.create(client, 12_345, waf_enabled: true)
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 400, message: "Bad request"}

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/shield/shield-zone", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.Shield.create(client, 12_345)
    end
  end

  describe "list/2" do
    test "returns parsed shield zones", %{client: client} do
      response = Bunnyx.Factory.shield_zone_list_response()

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/shield/shield-zones", opts ->
        assert opts[:params] == %{}
        {:ok, response}
      end)

      assert {:ok, result} = Bunnyx.Shield.list(client)
      assert [%Bunnyx.Shield.Zone{shield_zone_id: 100_001}] = result.items
      assert result.page["totalCount"] == 1
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 500, message: "Server error"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/shield/shield-zones", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.Shield.list(client)
    end
  end

  describe "list_active/2" do
    test "returns active shield zones", %{client: client} do
      response = Bunnyx.Factory.shield_zone_list_response()

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/shield/shield-zones/active", _opts ->
        {:ok, response}
      end)

      assert {:ok, result} = Bunnyx.Shield.list_active(client)
      assert [%Bunnyx.Shield.Zone{}] = result.items
    end
  end

  describe "get/2" do
    test "returns parsed shield zone", %{client: client} do
      response = Bunnyx.Factory.shield_zone_wrapped_response()

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/shield/shield-zone/100001", _opts ->
        {:ok, response}
      end)

      assert {:ok, %Bunnyx.Shield.Zone{shield_zone_id: 100_001, waf_enabled: true}} =
               Bunnyx.Shield.get(client, 100_001)
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 404, message: "Not found"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/shield/shield-zone/999", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.Shield.get(client, 999)
    end
  end

  describe "get_by_pull_zone/2" do
    test "returns shield zone for pull zone", %{client: client} do
      response = Bunnyx.Factory.shield_zone_wrapped_response()

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/shield/shield-zone/pull-zone/12345", _opts ->
        {:ok, response}
      end)

      assert {:ok, %Bunnyx.Shield.Zone{pull_zone_id: 12_345}} =
               Bunnyx.Shield.get_by_pull_zone(client, 12_345)
    end
  end

  describe "update/3" do
    test "sends attrs via PATCH and returns parsed zone", %{client: client} do
      response = Bunnyx.Factory.shield_zone_wrapped_response(%{"wafEnabled" => false})

      expect(Bunnyx.HTTP, :request, fn _req, :patch, "/shield/shield-zone", opts ->
        assert opts[:json]["shieldZoneId"] == 100_001
        assert opts[:json]["shieldZone"]["wafEnabled"] == false
        {:ok, response}
      end)

      assert {:ok, %Bunnyx.Shield.Zone{}} =
               Bunnyx.Shield.update(client, 100_001, waf_enabled: false)
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 400, message: "Bad request"}

      expect(Bunnyx.HTTP, :request, fn _req, :patch, "/shield/shield-zone", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.Shield.update(client, 100_001, waf_enabled: true)
    end
  end

  # -- WAF --

  describe "list_waf_rules/2" do
    test "returns WAF rules", %{client: client} do
      response = [%{"name" => "OWASP", "ruleGroups" => []}]

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/shield/waf/rules/100001", _opts ->
        {:ok, response}
      end)

      assert {:ok, ^response} = Bunnyx.Shield.list_waf_rules(client, 100_001)
    end
  end

  describe "list_custom_waf_rules/2" do
    test "returns custom rules with pagination", %{client: client} do
      response = %{
        "data" => [%{"id" => 1, "ruleName" => "Block SQL injection"}],
        "page" => %{"totalCount" => 1}
      }

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/shield/waf/custom-rules/100001", _opts ->
        {:ok, response}
      end)

      assert {:ok, result} = Bunnyx.Shield.list_custom_waf_rules(client, 100_001)
      assert [%{"id" => 1}] = result.items
    end
  end

  describe "create_custom_waf_rule/2" do
    test "sends rule and returns created rule", %{client: client} do
      response = %{"data" => %{"id" => 1, "ruleName" => "My Rule"}}

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/shield/waf/custom-rule", opts ->
        assert opts[:json]["shieldZoneId"] == 100_001
        assert opts[:json]["ruleName"] == "My Rule"
        {:ok, response}
      end)

      assert {:ok, %{"id" => 1}} =
               Bunnyx.Shield.create_custom_waf_rule(client,
                 shield_zone_id: 100_001,
                 rule_name: "My Rule"
               )
    end
  end

  describe "get_custom_waf_rule/2" do
    test "returns a custom rule", %{client: client} do
      response = %{"data" => %{"id" => 1, "ruleName" => "My Rule"}}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/shield/waf/custom-rule/1", _opts ->
        {:ok, response}
      end)

      assert {:ok, %{"id" => 1}} = Bunnyx.Shield.get_custom_waf_rule(client, 1)
    end
  end

  describe "update_custom_waf_rule/3" do
    test "sends updated attrs", %{client: client} do
      response = %{"data" => %{"id" => 1, "ruleName" => "Updated"}}

      expect(Bunnyx.HTTP, :request, fn _req, :patch, "/shield/waf/custom-rule/1", opts ->
        assert opts[:json]["ruleName"] == "Updated"
        {:ok, response}
      end)

      assert {:ok, %{"id" => 1}} =
               Bunnyx.Shield.update_custom_waf_rule(client, 1, rule_name: "Updated")
    end
  end

  describe "delete_custom_waf_rule/2" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :delete, "/shield/waf/custom-rule/1", _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.Shield.delete_custom_waf_rule(client, 1)
    end
  end

  describe "list_waf_profiles/1" do
    test "returns profiles", %{client: client} do
      response = %{"data" => [%{"id" => 1, "name" => "Standard"}]}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/shield/waf/profiles", _opts ->
        {:ok, response}
      end)

      assert {:ok, [%{"id" => 1}]} = Bunnyx.Shield.list_waf_profiles(client)
    end
  end

  describe "get_default_waf_config/1" do
    test "returns default config", %{client: client} do
      response = %{"data" => %{"variables" => []}}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/shield/waf/engine-config/default", _opts ->
        {:ok, response}
      end)

      assert {:ok, %{"variables" => []}} = Bunnyx.Shield.get_default_waf_config(client)
    end
  end

  describe "list_waf_rules_by_plan/1" do
    test "returns rules by plan", %{client: client} do
      response = [%{"plan" => "basic", "rules" => []}]

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/shield/waf/rules/plan", _opts ->
        {:ok, response}
      end)

      assert {:ok, ^response} = Bunnyx.Shield.list_waf_rules_by_plan(client)
    end
  end

  describe "list_triggered_waf_rules/2" do
    test "returns triggered rules", %{client: client} do
      response = %{"triggeredRules" => [], "totalTriggeredRules" => 0}

      expect(Bunnyx.HTTP, :request, fn _req,
                                       :get,
                                       "/shield/waf/rules/review-triggered/100001",
                                       _opts ->
        {:ok, response}
      end)

      assert {:ok, ^response} = Bunnyx.Shield.list_triggered_waf_rules(client, 100_001)
    end
  end

  describe "update_triggered_waf_rule/4" do
    test "sends rule action update", %{client: client} do
      response = %{"success" => true}

      expect(Bunnyx.HTTP, :request, fn _req,
                                       :post,
                                       "/shield/waf/rules/review-triggered/100001",
                                       opts ->
        assert opts[:json] == %{"ruleId" => "rule-1", "action" => 1}
        {:ok, response}
      end)

      assert {:ok, _} =
               Bunnyx.Shield.update_triggered_waf_rule(client, 100_001, "rule-1", 1)
    end
  end

  describe "get_waf_ai_recommendation/3" do
    test "returns AI recommendation", %{client: client} do
      response = %{"recommendation" => "block"}

      expect(Bunnyx.HTTP, :request, fn _req,
                                       :get,
                                       "/shield/waf/rules/review-triggered/ai-recommendation/100001/rule-1",
                                       _opts ->
        {:ok, response}
      end)

      assert {:ok, ^response} =
               Bunnyx.Shield.get_waf_ai_recommendation(client, 100_001, "rule-1")
    end
  end

  describe "list_waf_enums/1" do
    test "returns enum mappings", %{client: client} do
      response = %{"actionTypes" => %{}}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/shield/waf/enums", _opts ->
        {:ok, response}
      end)

      assert {:ok, ^response} = Bunnyx.Shield.list_waf_enums(client)
    end
  end

  # -- Rate Limiting --

  describe "list_rate_limits/2" do
    test "returns rate limits", %{client: client} do
      response = %{"data" => [%{"id" => 1}], "page" => %{"totalCount" => 1}}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/shield/rate-limits/100001", _opts ->
        {:ok, response}
      end)

      assert {:ok, result} = Bunnyx.Shield.list_rate_limits(client, 100_001)
      assert [%{"id" => 1}] = result.items
    end
  end

  describe "get_rate_limit/3" do
    test "returns a rate limit", %{client: client} do
      response = %{"data" => %{"id" => 1, "ruleName" => "API limit"}}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/shield/rate-limit/100001/1", _opts ->
        {:ok, response}
      end)

      assert {:ok, %{"id" => 1}} = Bunnyx.Shield.get_rate_limit(client, 100_001, 1)
    end
  end

  describe "create_rate_limit/2" do
    test "sends rate limit config", %{client: client} do
      response = %{"data" => %{"id" => 1}}

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/shield/rate-limit", opts ->
        assert opts[:json]["shieldZoneId"] == 100_001
        assert opts[:json]["ruleName"] == "API limit"
        {:ok, response}
      end)

      assert {:ok, %{"id" => 1}} =
               Bunnyx.Shield.create_rate_limit(client,
                 shield_zone_id: 100_001,
                 rule_name: "API limit",
                 rule_configuration: %{}
               )
    end
  end

  describe "update_rate_limit/3" do
    test "sends updated attrs", %{client: client} do
      response = %{"data" => %{"id" => 1}}

      expect(Bunnyx.HTTP, :request, fn _req, :patch, "/shield/rate-limit/1", opts ->
        assert opts[:json]["ruleName"] == "Updated"
        {:ok, response}
      end)

      assert {:ok, _} = Bunnyx.Shield.update_rate_limit(client, 1, rule_name: "Updated")
    end
  end

  describe "delete_rate_limit/2" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :delete, "/shield/rate-limit/1", _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.Shield.delete_rate_limit(client, 1)
    end
  end

  # -- Access Lists --

  describe "list_access_lists/2" do
    test "returns access lists", %{client: client} do
      response = %{"data" => [%{"id" => 1, "name" => "Block list"}]}

      expect(Bunnyx.HTTP, :request, fn _req,
                                       :get,
                                       "/shield/shield-zone/100001/access-lists",
                                       _opts ->
        {:ok, response}
      end)

      assert {:ok, [%{"id" => 1}]} = Bunnyx.Shield.list_access_lists(client, 100_001)
    end
  end

  describe "get_access_list/3" do
    test "returns an access list", %{client: client} do
      response = %{"data" => %{"id" => 1, "name" => "Block list"}}

      expect(Bunnyx.HTTP, :request, fn _req,
                                       :get,
                                       "/shield/shield-zone/100001/access-lists/1",
                                       _opts ->
        {:ok, response}
      end)

      assert {:ok, %{"id" => 1}} = Bunnyx.Shield.get_access_list(client, 100_001, 1)
    end
  end

  describe "create_access_list/3" do
    test "sends access list attrs", %{client: client} do
      response = %{"data" => %{"id" => 1}}

      expect(Bunnyx.HTTP, :request, fn _req,
                                       :post,
                                       "/shield/shield-zone/100001/access-lists",
                                       opts ->
        assert opts[:json]["name"] == "Block IPs"
        assert opts[:json]["type"] == 0
        assert opts[:json]["content"] == "1.2.3.4\n5.6.7.8"
        {:ok, response}
      end)

      assert {:ok, %{"id" => 1}} =
               Bunnyx.Shield.create_access_list(client, 100_001,
                 name: "Block IPs",
                 type: 0,
                 content: "1.2.3.4\n5.6.7.8"
               )
    end
  end

  describe "update_access_list/4" do
    test "sends updated attrs", %{client: client} do
      response = %{"data" => %{"id" => 1}}

      expect(Bunnyx.HTTP, :request, fn _req,
                                       :put,
                                       "/shield/shield-zone/100001/access-lists/1",
                                       opts ->
        assert opts[:json]["content"] == "1.2.3.4"
        {:ok, response}
      end)

      assert {:ok, _} =
               Bunnyx.Shield.update_access_list(client, 100_001, 1,
                 name: "Updated",
                 content: "1.2.3.4"
               )
    end
  end

  describe "delete_access_list/3" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req,
                                       :delete,
                                       "/shield/shield-zone/100001/access-lists/1",
                                       _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.Shield.delete_access_list(client, 100_001, 1)
    end
  end

  describe "update_access_list_config/4" do
    test "sends config update", %{client: client} do
      response = %{"data" => %{"id" => 1}}

      expect(Bunnyx.HTTP, :request, fn _req,
                                       :patch,
                                       "/shield/shield-zone/100001/access-lists/configurations/1",
                                       opts ->
        assert opts[:json] == %{"isEnabled" => true, "action" => 1}
        {:ok, response}
      end)

      assert {:ok, _} =
               Bunnyx.Shield.update_access_list_config(client, 100_001, 1,
                 is_enabled: true,
                 action: 1
               )
    end
  end

  describe "list_access_list_enums/2" do
    test "returns enum types", %{client: client} do
      response = %{"accessListTypes" => %{}}

      expect(Bunnyx.HTTP, :request, fn _req,
                                       :get,
                                       "/shield/shield-zone/100001/access-lists/enums",
                                       _opts ->
        {:ok, response}
      end)

      assert {:ok, ^response} = Bunnyx.Shield.list_access_list_enums(client, 100_001)
    end
  end
end
