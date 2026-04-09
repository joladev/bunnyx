defmodule Bunnyx.ParamsTest do
  use ExUnit.Case, async: true

  alias Bunnyx.Params

  describe "map_keys!/2" do
    test "converts keyword list using mapping" do
      mapping = %{name: "Name", origin_url: "OriginUrl"}

      assert %{"Name" => "test", "OriginUrl" => "https://example.com"} =
               Params.map_keys!([name: "test", origin_url: "https://example.com"], mapping)
    end

    test "converts atom-keyed map using mapping" do
      mapping = %{name: "Name", origin_url: "OriginUrl"}

      assert %{"Name" => "test", "OriginUrl" => "https://example.com"} =
               Params.map_keys!(%{name: "test", origin_url: "https://example.com"}, mapping)
    end

    test "raises ArgumentError on unknown key with valid keys listed" do
      mapping = %{name: "Name", origin_url: "OriginUrl"}

      error =
        assert_raise ArgumentError, fn ->
          Params.map_keys!([bad_key: "x"], mapping)
        end

      assert error.message =~ "unknown key :bad_key"
      assert error.message =~ ":name"
      assert error.message =~ ":origin_url"
    end

    test "returns empty map for empty list" do
      assert %{} = Params.map_keys!([], %{name: "Name"})
    end
  end

  describe "map_keys/2" do
    test "converts keyword list using mapping" do
      mapping = %{page: "page", per_page: "perPage"}
      assert %{"page" => 1, "perPage" => 10} = Params.map_keys([page: 1, per_page: 10], mapping)
    end
  end

  describe "maybe_put/3" do
    test "adds value when not nil" do
      assert [key: "value"] = Params.maybe_put([], :key, "value")
    end

    test "skips when nil" do
      assert [] = Params.maybe_put([], :key, nil)
    end
  end

  describe "maybe_put_map/3" do
    test "adds value when not nil" do
      assert %{"key" => "value"} = Params.maybe_put_map(%{}, "key", "value")
    end

    test "skips when nil" do
      assert %{} = Params.maybe_put_map(%{}, "key", nil)
    end
  end
end
