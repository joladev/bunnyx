defmodule Bunnyx.VideoLibraryTest do
  use ExUnit.Case, async: true
  use Mimic

  setup do
    %{client: Bunnyx.new(api_key: "sk-test")}
  end

  describe "list/2" do
    test "returns parsed video libraries", %{client: client} do
      response = Bunnyx.Factory.video_library_list_response()

      expect(Bunnyx.HTTP, :request, fn req, :get, "/videolibrary", opts ->
        assert req == client.req
        assert opts[:params] == %{}
        {:ok, response}
      end)

      assert {:ok, page} = Bunnyx.VideoLibrary.list(client)
      assert [%Bunnyx.VideoLibrary{id: 90_001, name: "my-library"}] = page.items
      assert page.current_page == 1
      assert page.total_items == 1
      assert page.has_more_items == false
    end

    test "passes query params", %{client: client} do
      response = Bunnyx.Factory.video_library_list_response()

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/videolibrary", opts ->
        assert opts[:params] == %{"page" => 2, "perPage" => 10, "search" => "test"}
        {:ok, response}
      end)

      Bunnyx.VideoLibrary.list(client, page: 2, per_page: 10, search: "test")
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 500, message: "Server error"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/videolibrary", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.VideoLibrary.list(client)
    end
  end

  describe "get/2" do
    test "returns parsed video library", %{client: client} do
      response = Bunnyx.Factory.video_library_response()

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/videolibrary/90001", _opts ->
        {:ok, response}
      end)

      assert {:ok, %Bunnyx.VideoLibrary{id: 90_001, name: "my-library", video_count: 42}} =
               Bunnyx.VideoLibrary.get(client, 90_001)
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 404, message: "Not found"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/videolibrary/999", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.VideoLibrary.get(client, 999)
    end
  end

  describe "create/2" do
    test "sends attrs and returns parsed video library", %{client: client} do
      response = Bunnyx.Factory.video_library_response(%{"Name" => "new-lib"})

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/videolibrary", opts ->
        assert opts[:json] == %{"Name" => "new-lib", "ReplicationRegions" => ["NY"]}
        {:ok, response}
      end)

      assert {:ok, %Bunnyx.VideoLibrary{name: "new-lib"}} =
               Bunnyx.VideoLibrary.create(client, name: "new-lib", replication_regions: ["NY"])
    end
  end

  describe "update/3" do
    test "sends attrs to correct path", %{client: client} do
      response = Bunnyx.Factory.video_library_response(%{"EnableTranscribing" => true})

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/videolibrary/90001", opts ->
        assert opts[:json] == %{"EnableTranscribing" => true}
        {:ok, response}
      end)

      assert {:ok, %Bunnyx.VideoLibrary{enable_transcribing: true}} =
               Bunnyx.VideoLibrary.update(client, 90_001, enable_transcribing: true)
    end
  end

  describe "delete/2" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :delete, "/videolibrary/90001", _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.VideoLibrary.delete(client, 90_001)
    end
  end

  describe "languages/1" do
    test "returns language list", %{client: client} do
      response = [%{"ShortCode" => "en", "Name" => "English"}]

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/videolibrary/languages", _opts ->
        {:ok, response}
      end)

      assert {:ok, [%{"ShortCode" => "en", "Name" => "English"}]} =
               Bunnyx.VideoLibrary.languages(client)
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 500, message: "Server error"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/videolibrary/languages", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.VideoLibrary.languages(client)
    end
  end

  describe "reset_api_key/2" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :post, "/videolibrary/90001/resetApiKey", _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.VideoLibrary.reset_api_key(client, 90_001)
    end
  end

  describe "reset_all_api_keys/1" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :post, "/videolibrary/resetApiKey", _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.VideoLibrary.reset_all_api_keys(client)
    end
  end

  describe "reset_read_only_api_key/2" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req,
                                       :post,
                                       "/videolibrary/90001/resetReadOnlyApiKey",
                                       _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.VideoLibrary.reset_read_only_api_key(client, 90_001)
    end
  end

  describe "reset_all_read_only_api_keys/1" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :post, "/videolibrary/resetReadOnlyApiKey", _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.VideoLibrary.reset_all_read_only_api_keys(client)
    end
  end

  describe "add_watermark/3" do
    test "sends image data and returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :put, "/videolibrary/90001/watermark", opts ->
        assert opts[:body] == <<0, 1, 2, 3>>
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.VideoLibrary.add_watermark(client, 90_001, <<0, 1, 2, 3>>)
    end
  end

  describe "remove_watermark/2" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :delete, "/videolibrary/90001/watermark", _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.VideoLibrary.remove_watermark(client, 90_001)
    end
  end

  describe "add_allowed_referrer/3" do
    test "sends hostname and returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req,
                                       :post,
                                       "/videolibrary/90001/addAllowedReferrer",
                                       opts ->
        assert opts[:json] == %{"Hostname" => "example.com"}
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.VideoLibrary.add_allowed_referrer(client, 90_001, "example.com")
    end
  end

  describe "remove_allowed_referrer/3" do
    test "sends hostname and returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req,
                                       :post,
                                       "/videolibrary/90001/removeAllowedReferrer",
                                       opts ->
        assert opts[:json] == %{"Hostname" => "example.com"}
        {:ok, ""}
      end)

      assert {:ok, nil} =
               Bunnyx.VideoLibrary.remove_allowed_referrer(client, 90_001, "example.com")
    end
  end

  describe "add_blocked_referrer/3" do
    test "sends hostname and returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req,
                                       :post,
                                       "/videolibrary/90001/addBlockedReferrer",
                                       opts ->
        assert opts[:json] == %{"Hostname" => "spam.com"}
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.VideoLibrary.add_blocked_referrer(client, 90_001, "spam.com")
    end
  end

  describe "remove_blocked_referrer/3" do
    test "sends hostname and returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req,
                                       :post,
                                       "/videolibrary/90001/removeBlockedReferrer",
                                       opts ->
        assert opts[:json] == %{"Hostname" => "spam.com"}
        {:ok, ""}
      end)

      assert {:ok, nil} =
               Bunnyx.VideoLibrary.remove_blocked_referrer(client, 90_001, "spam.com")
    end
  end

  describe "transcribing_statistics/3" do
    test "returns statistics", %{client: client} do
      response = %{"TotalCharactersUsed" => 50_000}

      expect(Bunnyx.HTTP, :request, fn _req,
                                       :get,
                                       "/videolibrary/90001/transcribing/statistics",
                                       opts ->
        assert opts[:params] == %{}
        {:ok, response}
      end)

      assert {:ok, %{"TotalCharactersUsed" => 50_000}} =
               Bunnyx.VideoLibrary.transcribing_statistics(client, 90_001)
    end

    test "passes date params", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req,
                                       :get,
                                       "/videolibrary/90001/transcribing/statistics",
                                       opts ->
        assert opts[:params] == %{"dateFrom" => "2025-06-01", "dateTo" => "2025-06-30"}
        {:ok, %{}}
      end)

      Bunnyx.VideoLibrary.transcribing_statistics(client, 90_001,
        date_from: "2025-06-01",
        date_to: "2025-06-30"
      )
    end
  end

  describe "resolve" do
    test "accepts keyword list as client" do
      response = Bunnyx.Factory.video_library_response()

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/videolibrary/1", _opts ->
        {:ok, response}
      end)

      assert {:ok, %Bunnyx.VideoLibrary{}} = Bunnyx.VideoLibrary.get([api_key: "sk-test"], 1)
    end
  end
end
