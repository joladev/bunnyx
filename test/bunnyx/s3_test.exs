defmodule Bunnyx.S3Test do
  use ExUnit.Case, async: true
  use Mimic

  setup do
    %{client: Bunnyx.S3.new(zone: "my-zone", storage_key: "pw-secret", region: "de")}
  end

  describe "new/1" do
    test "configures aws_sigv4 on the request" do
      client = Bunnyx.S3.new(zone: "test-zone", storage_key: "pw-123", region: "ny")

      assert %Bunnyx.S3{zone: "test-zone"} = client
      assert client.req.options.aws_sigv4[:service] == :s3
      assert client.req.options.aws_sigv4[:access_key_id] == "test-zone"
      assert client.req.options.aws_sigv4[:secret_access_key] == "pw-123"
      assert client.req.options.aws_sigv4[:region] == "ny"
    end

    test "raises on missing required options" do
      assert_raise KeyError, fn -> Bunnyx.S3.new(zone: "z", storage_key: "k") end
      assert_raise KeyError, fn -> Bunnyx.S3.new(zone: "z", region: "de") end
      assert_raise KeyError, fn -> Bunnyx.S3.new(storage_key: "k", region: "de") end
    end
  end

  describe "put/4" do
    test "uploads data and returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :put, "/my-zone/images/logo.png", opts ->
        assert opts[:body] == <<1, 2, 3>>
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.S3.put(client, "images/logo.png", <<1, 2, 3>>)
    end

    test "sends checksum header when provided", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :put, "/my-zone/file.txt", opts ->
        assert opts[:body] == "hello"
        assert opts[:headers] == [{"x-amz-checksum-sha256", "abc123=="}]
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.S3.put(client, "file.txt", "hello", checksum: "abc123==")
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 403, message: "InvalidSecurity"}

      expect(Bunnyx.HTTP, :request, fn _req, :put, "/my-zone/file.txt", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.S3.put(client, "file.txt", "data")
    end
  end

  describe "get/3" do
    test "downloads object and returns binary", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :get, "/my-zone/images/logo.png", _opts ->
        {:ok, <<1, 2, 3>>}
      end)

      assert {:ok, <<1, 2, 3>>} = Bunnyx.S3.get(client, "images/logo.png")
    end

    test "sends range header when provided", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :get, "/my-zone/large.bin", opts ->
        assert opts[:headers] == [{"range", "bytes=0-1023"}]
        {:ok, <<0::size(1024)-unit(8)>>}
      end)

      assert {:ok, _} = Bunnyx.S3.get(client, "large.bin", range: "bytes=0-1023")
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 404, message: "NoSuchKey"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/my-zone/missing.txt", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.S3.get(client, "missing.txt")
    end
  end

  describe "delete/2" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :delete, "/my-zone/old.txt", _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.S3.delete(client, "old.txt")
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 404, message: "NoSuchKey"}

      expect(Bunnyx.HTTP, :request, fn _req, :delete, "/my-zone/missing.txt", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.S3.delete(client, "missing.txt")
    end
  end

  describe "head/2" do
    test "returns response headers", %{client: client} do
      headers = %{
        "content-length" => ["1024"],
        "content-type" => ["image/png"],
        "etag" => ["\"abc123\""],
        "last-modified" => ["Tue, 01 Jun 2025 12:00:00 GMT"]
      }

      expect(Bunnyx.HTTP, :request, fn _req, :head, "/my-zone/images/logo.png", _opts ->
        {:ok, headers}
      end)

      assert {:ok, ^headers} = Bunnyx.S3.head(client, "images/logo.png")
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 404, message: "NoSuchKey"}

      expect(Bunnyx.HTTP, :request, fn _req, :head, "/my-zone/missing.txt", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.S3.head(client, "missing.txt")
    end
  end

  describe "resolve" do
    test "accepts keyword list as client" do
      expect(Bunnyx.HTTP, :request, fn _req, :get, "/test-zone/file.txt", _opts ->
        {:ok, "content"}
      end)

      assert {:ok, "content"} =
               Bunnyx.S3.get([zone: "test-zone", storage_key: "pw", region: "de"], "file.txt")
    end
  end
end
