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

    test "passes body as :json option", %{req: req} do
      expect(Req, :request, fn _req, opts ->
        assert opts[:json] == %{"Name" => "test"}
        {:ok, %Req.Response{status: 200, body: %{}}}
      end)

      Bunnyx.HTTP.request(req, :post, "/pullzone", body: %{"Name" => "test"})
    end

    test "passes params through", %{req: req} do
      expect(Req, :request, fn _req, opts ->
        assert opts[:params] == %{"page" => 1}
        {:ok, %Req.Response{status: 200, body: %{}}}
      end)

      Bunnyx.HTTP.request(req, :get, "/pullzone", params: %{"page" => 1})
    end
  end
end
