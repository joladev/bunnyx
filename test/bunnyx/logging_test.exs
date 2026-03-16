defmodule Bunnyx.LoggingTest do
  use ExUnit.Case, async: true
  use Mimic

  setup do
    %{client: Bunnyx.new(api_key: "sk-test")}
  end

  describe "cdn/3" do
    test "downloads CDN logs for a date", %{client: client} do
      log_line = "HIT|200|1622548800000|1024|12345|1.2.3.4|https://example.com|/index.html"

      expect(Bunnyx.HTTP, :request, fn req, :get, "/06-01-25/12345.log", _opts ->
        assert req.options.base_url == "https://logging.bunnycdn.com"
        {:ok, log_line}
      end)

      assert {:ok, ^log_line} = Bunnyx.Logging.cdn(client, 12_345, ~D[2025-06-01])
    end

    test "accepts string date format", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :get, "/06-01-25/12345.log", _opts ->
        {:ok, ""}
      end)

      assert {:ok, ""} = Bunnyx.Logging.cdn(client, 12_345, "06-01-25")
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 404, message: "Not found"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/06-01-25/12345.log", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.Logging.cdn(client, 12_345, ~D[2025-06-01])
    end
  end

  describe "origin_errors/3" do
    test "downloads origin error logs for a date", %{client: client} do
      response = [%{"logId" => "abc", "message" => "dns_lookup failed"}]

      expect(Bunnyx.HTTP, :request, fn req, :get, "/12345/06-01-2025", _opts ->
        assert req.options.base_url == "https://cdn-origin-logging.bunny.net"
        {:ok, response}
      end)

      assert {:ok, ^response} = Bunnyx.Logging.origin_errors(client, 12_345, ~D[2025-06-01])
    end

    test "accepts string date format", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :get, "/12345/06-01-2025", _opts ->
        {:ok, []}
      end)

      assert {:ok, []} = Bunnyx.Logging.origin_errors(client, 12_345, "06-01-2025")
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 500, message: "Server error"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/12345/06-01-2025", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.Logging.origin_errors(client, 12_345, ~D[2025-06-01])
    end
  end
end
