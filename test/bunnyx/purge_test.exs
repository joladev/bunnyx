defmodule Bunnyx.PurgeTest do
  use ExUnit.Case, async: true
  use Mimic

  setup do
    %{client: Bunnyx.new(api_key: "sk-test")}
  end

  describe "url/3" do
    test "sends POST to /purge with url as query param", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn req, :post, "/purge", opts ->
        assert req == client.req
        assert opts[:params] == %{"url" => "https://example.com/image.png"}
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.Purge.url(client, "https://example.com/image.png")
    end

    test "passes async and exact_path as query params", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :post, "/purge", opts ->
        assert opts[:params] == %{
                 "url" => "https://example.com/",
                 "async" => true,
                 "exactPath" => true
               }

        {:ok, ""}
      end)

      Bunnyx.Purge.url(client, "https://example.com/", async: true, exact_path: true)
    end

    test "omits optional params when not provided", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :post, "/purge", opts ->
        assert opts[:params] == %{"url" => "https://example.com/style.css"}
        {:ok, ""}
      end)

      Bunnyx.Purge.url(client, "https://example.com/style.css")
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 500, message: "Server error"}

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/purge", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.Purge.url(client, "https://example.com/image.png")
    end

    test "accepts keyword list as client" do
      expect(Bunnyx.HTTP, :request, fn _req, :post, "/purge", _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.Purge.url([api_key: "sk-test"], "https://example.com/x.png")
    end
  end

  describe "pull_zone/3" do
    test "sends POST to /pullzone/{id}/purgeCache with empty opts", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn req, :post, "/pullzone/12345/purgeCache", opts ->
        assert req == client.req
        assert opts == []
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.Purge.pull_zone(client, 12_345)
    end

    test "sends cache_tag as JSON body", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :post, "/pullzone/12345/purgeCache", opts ->
        assert opts[:json] == %{"CacheTag" => "images"}
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.Purge.pull_zone(client, 12_345, cache_tag: "images")
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 404, message: "Not found"}

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/pullzone/999/purgeCache", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.Purge.pull_zone(client, 999)
    end
  end
end
