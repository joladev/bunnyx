defmodule Bunnyx.HTTPTest do
  use ExUnit.Case, async: true
  use Mimic

  setup do
    %{req: Req.new(base_url: "https://api.bunny.net")}
  end

  describe "request/4" do
    test "returns {:ok, body} on 2xx", %{req: req} do
      expect(Req, :request, fn _req, _opts ->
        {:ok, %Req.Response{status: 200, body: %{"Id" => 1}}}
      end)

      assert {:ok, %{"Id" => 1}} = Bunnyx.HTTP.request(req, :get, "/pullzone")
    end

    test "returns {:ok, nil} on 204 with empty body", %{req: req} do
      expect(Req, :request, fn _req, _opts ->
        {:ok, %Req.Response{status: 204, body: ""}}
      end)

      assert {:ok, ""} = Bunnyx.HTTP.request(req, :delete, "/pullzone/1")
    end

    test "returns error on 4xx with message", %{req: req} do
      expect(Req, :request, fn _req, _opts ->
        {:ok, %Req.Response{status: 404, body: %{"Message" => "Not found"}}}
      end)

      assert {:error, %Bunnyx.Error{status: 404, message: "Not found"}} =
               Bunnyx.HTTP.request(req, :get, "/pullzone/999")
    end

    test "returns error on 5xx", %{req: req} do
      expect(Req, :request, fn _req, _opts ->
        {:ok,
         %Req.Response{
           status: 500,
           body: %{"Message" => "Server error", "Errors" => [%{"Field" => "name"}]}
         }}
      end)

      assert {:error,
              %Bunnyx.Error{status: 500, message: "Server error", errors: [%{"Field" => "name"}]}} =
               Bunnyx.HTTP.request(req, :get, "/pullzone")
    end

    test "returns error on transport failure", %{req: req} do
      expect(Req, :request, fn _req, _opts ->
        {:error, %Mint.TransportError{reason: :timeout}}
      end)

      assert {:error, %Bunnyx.Error{status: nil, message: "timeout"}} =
               Bunnyx.HTTP.request(req, :get, "/pullzone")
    end

    test "passes json through", %{req: req} do
      expect(Req, :request, fn _req, opts ->
        assert opts[:json] == %{"Name" => "test"}
        {:ok, %Req.Response{status: 200, body: %{}}}
      end)

      Bunnyx.HTTP.request(req, :post, "/pullzone", json: %{"Name" => "test"})
    end

    test "passes body through", %{req: req} do
      expect(Req, :request, fn _req, opts ->
        assert opts[:body] == "raw binary"
        {:ok, %Req.Response{status: 200, body: %{}}}
      end)

      Bunnyx.HTTP.request(req, :put, "/zone/file.txt", body: "raw binary")
    end

    test "passes params through", %{req: req} do
      expect(Req, :request, fn _req, opts ->
        assert opts[:params] == %{"page" => 1}
        {:ok, %Req.Response{status: 200, body: %{}}}
      end)

      Bunnyx.HTTP.request(req, :get, "/pullzone", params: %{"page" => 1})
    end

    test "HEAD returns headers instead of body", %{req: req} do
      expect(Req, :request, fn _req, _opts ->
        {:ok, %Req.Response{status: 200, body: "", headers: %{"content-length" => ["1024"]}}}
      end)

      assert {:ok, %{"content-length" => ["1024"]}} =
               Bunnyx.HTTP.request(req, :head, "/zone/file.txt", [])
    end

    test "return_headers: true returns {body, headers} tuple", %{req: req} do
      expect(Req, :request, fn _req, _opts ->
        {:ok, %Req.Response{status: 200, body: "ok", headers: %{"etag" => ["\"abc\""]}}}
      end)

      assert {:ok, {"ok", %{"etag" => ["\"abc\""]}}} =
               Bunnyx.HTTP.request(req, :put, "/zone/file.txt",
                 body: "data",
                 return_headers: true
               )
    end

    test "receive_timeout is forwarded to Req", %{req: req} do
      expect(Req, :request, fn _req, opts ->
        assert opts[:receive_timeout] == 60_000
        {:ok, %Req.Response{status: 200, body: %{}}}
      end)

      Bunnyx.HTTP.request(req, :get, "/pullzone", receive_timeout: 60_000)
    end

    test "sanitize redacts AccessKey from error messages", %{req: req} do
      expect(Req, :request, fn _req, _opts ->
        {:error, %RuntimeError{message: "failed with AccessKey: sk-secret-123 in header"}}
      end)

      assert {:error, %Bunnyx.Error{message: message}} =
               Bunnyx.HTTP.request(req, :get, "/pullzone", [])

      assert message =~ "AccessKey: [REDACTED]"
      refute message =~ "sk-secret-123"
    end

    test "sanitize redacts Bearer tokens", %{req: req} do
      expect(Req, :request, fn _req, _opts ->
        {:error, %RuntimeError{message: "auth failed Bearer eyJhbGciOiJI..."}}
      end)

      assert {:error, %Bunnyx.Error{message: message}} =
               Bunnyx.HTTP.request(req, :get, "/pullzone", [])

      assert message =~ "Bearer [REDACTED]"
      refute message =~ "eyJhbGciOiJI"
    end

    test "extracts message from XML error responses", %{req: req} do
      xml_body =
        "<Error><Code>NoSuchKey</Code><Message>The specified key does not exist.</Message></Error>"

      expect(Req, :request, fn _req, _opts ->
        {:ok, %Req.Response{status: 404, body: xml_body}}
      end)

      assert {:error, %Bunnyx.Error{message: "The specified key does not exist."}} =
               Bunnyx.HTTP.request(req, :get, "/zone/missing.txt", [])
    end
  end
end
