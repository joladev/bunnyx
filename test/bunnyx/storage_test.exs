defmodule Bunnyx.StorageTest do
  use ExUnit.Case, async: true
  use Mimic

  setup do
    %{client: Bunnyx.Storage.new(storage_key: "pw-test", zone: "my-zone")}
  end

  describe "new/1" do
    test "builds client with default region" do
      client = Bunnyx.Storage.new(storage_key: "pw-test", zone: "my-zone")
      assert client.zone == "my-zone"
      assert client.req.options.base_url == "https://storage.bunnycdn.com"
    end

    test "builds client with region" do
      client = Bunnyx.Storage.new(storage_key: "pw-test", zone: "my-zone", region: "ny")
      assert client.req.options.base_url == "https://ny.storage.bunnycdn.com"
    end

    test "raises on missing storage_key" do
      assert_raise KeyError, fn -> Bunnyx.Storage.new(zone: "my-zone") end
    end

    test "raises on missing zone" do
      assert_raise KeyError, fn -> Bunnyx.Storage.new(storage_key: "pw-test") end
    end
  end

  describe "list/2" do
    test "returns parsed objects", %{client: client} do
      response = [Bunnyx.Factory.storage_object_response()]

      expect(Bunnyx.HTTP, :request, fn req, :get, "/my-zone/", _opts ->
        assert req == client.req
        {:ok, response}
      end)

      assert {:ok, [%Bunnyx.Storage.Object{guid: "a1b2c3d4-e5f6-7890-abcd-ef1234567890"}]} =
               Bunnyx.Storage.list(client)
    end

    test "ensures trailing slash on path", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :get, "/my-zone/images/", _opts ->
        {:ok, []}
      end)

      Bunnyx.Storage.list(client, "/images")
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 404, message: "Not found"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/my-zone/missing/", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.Storage.list(client, "/missing")
    end
  end

  describe "get/2" do
    test "returns binary body", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :get, "/my-zone/images/logo.png", _opts ->
        {:ok, <<137, 80, 78, 71>>}
      end)

      assert {:ok, <<137, 80, 78, 71>>} = Bunnyx.Storage.get(client, "/images/logo.png")
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 404, message: "Not found"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/my-zone/missing.txt", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.Storage.get(client, "/missing.txt")
    end
  end

  describe "put/4" do
    test "uploads binary data", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :put, "/my-zone/images/new.png", opts ->
        assert opts[:body] == "binary data"
        {:ok, %{"HttpCode" => 201, "Message" => "File uploaded."}}
      end)

      assert {:ok, nil} = Bunnyx.Storage.put(client, "/images/new.png", "binary data")
    end

    test "adds checksum header when provided", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :put, "/my-zone/file.txt", opts ->
        assert opts[:body] == "content"
        assert {"Checksum", "abc123"} in opts[:headers]
        {:ok, %{"HttpCode" => 201, "Message" => "File uploaded."}}
      end)

      assert {:ok, nil} =
               Bunnyx.Storage.put(client, "/file.txt", "content", checksum: "abc123")
    end

    test "omits headers when no checksum", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :put, "/my-zone/file.txt", opts ->
        refute Keyword.has_key?(opts, :headers)
        {:ok, %{"HttpCode" => 201, "Message" => "File uploaded."}}
      end)

      assert {:ok, nil} = Bunnyx.Storage.put(client, "/file.txt", "content")
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 401, message: "Unauthorized"}

      expect(Bunnyx.HTTP, :request, fn _req, :put, "/my-zone/file.txt", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.Storage.put(client, "/file.txt", "content")
    end
  end

  describe "delete/2" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :delete, "/my-zone/images/old.png", _opts ->
        {:ok, %{"HttpCode" => 200, "Message" => "File deleted."}}
      end)

      assert {:ok, nil} = Bunnyx.Storage.delete(client, "/images/old.png")
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 404, message: "Not found"}

      expect(Bunnyx.HTTP, :request, fn _req, :delete, "/my-zone/missing.txt", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.Storage.delete(client, "/missing.txt")
    end
  end

  describe "resolve" do
    test "accepts keyword list as client" do
      expect(Bunnyx.HTTP, :request, fn _req, :get, "/my-zone/", _opts ->
        {:ok, []}
      end)

      assert {:ok, []} = Bunnyx.Storage.list(storage_key: "pw-test", zone: "my-zone")
    end
  end

  describe "build_path" do
    test "handles path without leading slash", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :get, "/my-zone/file.txt", _opts ->
        {:ok, "content"}
      end)

      assert {:ok, "content"} = Bunnyx.Storage.get(client, "file.txt")
    end
  end
end
