defmodule Bunnyx.StreamTest do
  use ExUnit.Case, async: true
  use Mimic

  setup do
    %{client: Bunnyx.Stream.new(api_key: "lib-key-123", library_id: 90_001)}
  end

  describe "list/2" do
    test "returns parsed videos", %{client: client} do
      response = Bunnyx.Factory.video_list_response()

      expect(Bunnyx.HTTP, :request, fn req, :get, "/library/90001/videos", opts ->
        assert req == client.req
        assert opts[:params] == %{}
        {:ok, response}
      end)

      assert {:ok, page} = Bunnyx.Stream.list(client)

      assert [
               %Bunnyx.Stream.Video{
                 guid: "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
                 title: "My Video"
               }
             ] =
               page.items

      assert page.current_page == 1
      assert page.total_items == 1
    end

    test "passes query params", %{client: client} do
      response = Bunnyx.Factory.video_list_response()

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/library/90001/videos", opts ->
        assert opts[:params] == %{"page" => 2, "itemsPerPage" => 10, "search" => "test"}
        {:ok, response}
      end)

      Bunnyx.Stream.list(client, page: 2, per_page: 10, search: "test")
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 500, message: "Server error"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/library/90001/videos", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.Stream.list(client)
    end
  end

  describe "get/2" do
    test "returns parsed video", %{client: client} do
      response = Bunnyx.Factory.video_response()

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/library/90001/videos/abc-123", _opts ->
        {:ok, response}
      end)

      assert {:ok, %Bunnyx.Stream.Video{title: "My Video", views: 1000}} =
               Bunnyx.Stream.get(client, "abc-123")
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 404, message: "Not found"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/library/90001/videos/bad-id", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.Stream.get(client, "bad-id")
    end
  end

  describe "create/2" do
    test "sends attrs and returns parsed video", %{client: client} do
      response = Bunnyx.Factory.video_response(%{"title" => "New Video"})

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/library/90001/videos", opts ->
        assert opts[:json] == %{"title" => "New Video"}
        {:ok, response}
      end)

      assert {:ok, %Bunnyx.Stream.Video{title: "New Video"}} =
               Bunnyx.Stream.create(client, title: "New Video")
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 400, message: "Bad request"}

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/library/90001/videos", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.Stream.create(client, title: "Bad")
    end
  end

  describe "update/3" do
    test "sends attrs to correct path", %{client: client} do
      response = Bunnyx.Factory.video_response(%{"title" => "Updated"})

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/library/90001/videos/abc-123", opts ->
        assert opts[:json] == %{"title" => "Updated"}
        {:ok, response}
      end)

      assert {:ok, %Bunnyx.Stream.Video{title: "Updated"}} =
               Bunnyx.Stream.update(client, "abc-123", title: "Updated")
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 500, message: "Server error"}

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/library/90001/videos/abc-123", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.Stream.update(client, "abc-123", title: "Bad")
    end
  end

  describe "delete/2" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :delete, "/library/90001/videos/abc-123", _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.Stream.delete(client, "abc-123")
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 404, message: "Not found"}

      expect(Bunnyx.HTTP, :request, fn _req, :delete, "/library/90001/videos/abc-123", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.Stream.delete(client, "abc-123")
    end
  end

  describe "upload/3" do
    test "sends binary data and returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :put, "/library/90001/videos/abc-123", opts ->
        assert opts[:body] == <<0, 1, 2, 3>>
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.Stream.upload(client, "abc-123", <<0, 1, 2, 3>>)
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 500, message: "Server error"}

      expect(Bunnyx.HTTP, :request, fn _req, :put, "/library/90001/videos/abc-123", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.Stream.upload(client, "abc-123", <<0>>)
    end
  end

  describe "fetch/2" do
    test "sends URL and returns parsed video", %{client: client} do
      response = Bunnyx.Factory.video_response()

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/library/90001/videos/fetch", opts ->
        assert opts[:json] == %{"url" => "https://example.com/video.mp4", "title" => "Fetched"}
        {:ok, response}
      end)

      assert {:ok, %Bunnyx.Stream.Video{}} =
               Bunnyx.Stream.fetch(client, url: "https://example.com/video.mp4", title: "Fetched")
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 400, message: "Bad request"}

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/library/90001/videos/fetch", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.Stream.fetch(client, url: "https://bad.url")
    end
  end

  # -- Video analytics --

  describe "video_statistics/2" do
    test "returns library statistics", %{client: client} do
      response = %{"viewsChart" => %{"2025-06-01" => 100}, "watchTimeChart" => %{}}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/library/90001/statistics", opts ->
        assert opts[:params] == %{}
        {:ok, response}
      end)

      assert {:ok, %{"viewsChart" => _}} = Bunnyx.Stream.video_statistics(client)
    end

    test "passes filter params", %{client: client} do
      response = %{"viewsChart" => %{}}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/library/90001/statistics", opts ->
        assert opts[:params]["videoGuid"] == "abc-123"
        assert opts[:params]["hourly"] == true
        {:ok, response}
      end)

      Bunnyx.Stream.video_statistics(client, video_guid: "abc-123", hourly: true)
    end
  end

  describe "video_play_data/2" do
    test "returns play data", %{client: client} do
      response = %{"videoPlaylistUrl" => "https://example.com/playlist.m3u8"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/library/90001/videos/abc-123/play", _opts ->
        {:ok, response}
      end)

      assert {:ok, %{"videoPlaylistUrl" => _}} = Bunnyx.Stream.video_play_data(client, "abc-123")
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 404, message: "Not found"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/library/90001/videos/abc-123/play", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.Stream.video_play_data(client, "abc-123")
    end
  end

  describe "video_heatmap_data/2" do
    test "returns raw heatmap data", %{client: client} do
      response = %{"data" => [0.1, 0.5, 0.8]}

      expect(Bunnyx.HTTP, :request, fn _req,
                                       :get,
                                       "/library/90001/videos/abc-123/play/heatmap",
                                       _opts ->
        {:ok, response}
      end)

      assert {:ok, _} = Bunnyx.Stream.video_heatmap_data(client, "abc-123")
    end
  end

  describe "video_storage_info/2" do
    test "returns storage breakdown", %{client: client} do
      response = %{"data" => %{"thumbnails" => 1024, "originals" => 52_428_800}}

      expect(Bunnyx.HTTP, :request, fn _req,
                                       :get,
                                       "/library/90001/videos/abc-123/storage",
                                       _opts ->
        {:ok, response}
      end)

      assert {:ok, _} = Bunnyx.Stream.video_storage_info(client, "abc-123")
    end
  end

  describe "video_resolutions/2" do
    test "returns resolution info", %{client: client} do
      response = %{"availableResolutions" => ["720p", "1080p"]}

      expect(Bunnyx.HTTP, :request, fn _req,
                                       :get,
                                       "/library/90001/videos/abc-123/resolutions",
                                       _opts ->
        {:ok, response}
      end)

      assert {:ok, _} = Bunnyx.Stream.video_resolutions(client, "abc-123")
    end
  end

  # -- Video actions --

  describe "add_output_codec/3" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req,
                                       :put,
                                       "/library/90001/videos/abc-123/outputs/2",
                                       _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.Stream.add_output_codec(client, "abc-123", 2)
    end
  end

  describe "cleanup_resolutions/3" do
    test "returns cleanup result", %{client: client} do
      response = %{"deletedFiles" => 3}

      expect(Bunnyx.HTTP, :request, fn _req,
                                       :post,
                                       "/library/90001/videos/abc-123/resolutions/cleanup",
                                       _opts ->
        {:ok, response}
      end)

      assert {:ok, %{"deletedFiles" => 3}} = Bunnyx.Stream.cleanup_resolutions(client, "abc-123")
    end
  end

  describe "repackage/3" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req,
                                       :post,
                                       "/library/90001/videos/abc-123/repackage",
                                       _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.Stream.repackage(client, "abc-123")
    end
  end

  describe "transcribe/3" do
    test "sends transcription settings", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req,
                                       :post,
                                       "/library/90001/videos/abc-123/transcribe",
                                       opts ->
        assert opts[:json]["targetLanguages"] == ["en", "de"]
        {:ok, ""}
      end)

      assert {:ok, nil} =
               Bunnyx.Stream.transcribe(client, "abc-123", target_languages: ["en", "de"])
    end
  end

  describe "smart_actions/3" do
    test "sends smart action settings", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :post, "/library/90001/videos/abc-123/smart", opts ->
        assert opts[:json]["generateTitle"] == true
        assert opts[:json]["generateChapters"] == true
        {:ok, ""}
      end)

      assert {:ok, nil} =
               Bunnyx.Stream.smart_actions(client, "abc-123",
                 generate_title: true,
                 generate_chapters: true
               )
    end
  end

  describe "oembed/3" do
    test "returns oEmbed data", %{client: client} do
      response = %{
        "version" => "1.0",
        "type" => "video",
        "title" => "My Video",
        "html" => "<iframe></iframe>",
        "width" => 1920,
        "height" => 1080
      }

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/OEmbed", opts ->
        assert opts[:params]["url"] == "https://video.bunnycdn.com/play/90001/abc-123"
        {:ok, response}
      end)

      assert {:ok, %{"type" => "video", "title" => "My Video"}} =
               Bunnyx.Stream.oembed(client, "https://video.bunnycdn.com/play/90001/abc-123")
    end
  end

  # -- Collections --

  describe "list_collections/2" do
    test "returns parsed collections", %{client: client} do
      response = Bunnyx.Factory.collection_list_response()

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/library/90001/collections", opts ->
        assert opts[:params] == %{}
        {:ok, response}
      end)

      assert {:ok, page} = Bunnyx.Stream.list_collections(client)
      assert [%Bunnyx.Stream.Collection{guid: "col-a1b2c3d4", name: "My Collection"}] = page.items
      assert page.total_items == 1
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 500, message: "Server error"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/library/90001/collections", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.Stream.list_collections(client)
    end
  end

  describe "get_collection/2" do
    test "returns parsed collection", %{client: client} do
      response = Bunnyx.Factory.collection_response()

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/library/90001/collections/col-123", _opts ->
        {:ok, response}
      end)

      assert {:ok, %Bunnyx.Stream.Collection{name: "My Collection"}} =
               Bunnyx.Stream.get_collection(client, "col-123")
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 404, message: "Not found"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/library/90001/collections/bad-id", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.Stream.get_collection(client, "bad-id")
    end
  end

  describe "create_collection/2" do
    test "sends name and returns parsed collection", %{client: client} do
      response = Bunnyx.Factory.collection_response(%{"name" => "New Col"})

      expect(Bunnyx.HTTP, :request, fn _req, :post, "/library/90001/collections", opts ->
        assert opts[:json] == %{"name" => "New Col"}
        {:ok, response}
      end)

      assert {:ok, %Bunnyx.Stream.Collection{name: "New Col"}} =
               Bunnyx.Stream.create_collection(client, "New Col")
    end
  end

  describe "update_collection/3" do
    test "sends name to correct path", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :post, "/library/90001/collections/col-123", opts ->
        assert opts[:json] == %{"name" => "Renamed"}
        {:ok, %{"success" => true}}
      end)

      assert {:ok, nil} = Bunnyx.Stream.update_collection(client, "col-123", "Renamed")
    end
  end

  describe "delete_collection/2" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req,
                                       :delete,
                                       "/library/90001/collections/col-123",
                                       _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.Stream.delete_collection(client, "col-123")
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 404, message: "Not found"}

      expect(Bunnyx.HTTP, :request, fn _req,
                                       :delete,
                                       "/library/90001/collections/col-123",
                                       _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.Stream.delete_collection(client, "col-123")
    end
  end

  # -- Video metadata --

  describe "add_caption/5" do
    test "sends caption data and returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req,
                                       :post,
                                       "/library/90001/videos/abc-123/captions/en",
                                       opts ->
        assert opts[:json] == %{
                 "srclang" => "en",
                 "label" => "English",
                 "captionsFile" => "base64data"
               }

        {:ok, ""}
      end)

      assert {:ok, nil} =
               Bunnyx.Stream.add_caption(client, "abc-123", "en", "English", "base64data")
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 500, message: "Server error"}

      expect(Bunnyx.HTTP, :request, fn _req,
                                       :post,
                                       "/library/90001/videos/abc-123/captions/en",
                                       _opts ->
        {:error, error}
      end)

      assert {:error, ^error} =
               Bunnyx.Stream.add_caption(client, "abc-123", "en", "English", "data")
    end
  end

  describe "delete_caption/3" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req,
                                       :delete,
                                       "/library/90001/videos/abc-123/captions/en",
                                       _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.Stream.delete_caption(client, "abc-123", "en")
    end
  end

  describe "set_thumbnail/3" do
    test "sends thumbnail URL and returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req,
                                       :post,
                                       "/library/90001/videos/abc-123/thumbnail",
                                       opts ->
        assert opts[:params] == %{"thumbnailUrl" => "https://example.com/thumb.jpg"}
        {:ok, ""}
      end)

      assert {:ok, nil} =
               Bunnyx.Stream.set_thumbnail(client, "abc-123", "https://example.com/thumb.jpg")
    end
  end

  describe "reencode/2" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req,
                                       :post,
                                       "/library/90001/videos/abc-123/reencode",
                                       _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.Stream.reencode(client, "abc-123")
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 500, message: "Server error"}

      expect(Bunnyx.HTTP, :request, fn _req,
                                       :post,
                                       "/library/90001/videos/abc-123/reencode",
                                       _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.Stream.reencode(client, "abc-123")
    end
  end

  describe "heatmap/2" do
    test "returns heatmap data", %{client: client} do
      response = %{"heatmap" => [0.1, 0.5, 0.8, 0.3]}

      expect(Bunnyx.HTTP, :request, fn _req,
                                       :get,
                                       "/library/90001/videos/abc-123/heatmap",
                                       _opts ->
        {:ok, response}
      end)

      assert {:ok, %{"heatmap" => [0.1, 0.5, 0.8, 0.3]}} =
               Bunnyx.Stream.heatmap(client, "abc-123")
    end
  end

  describe "resolve" do
    test "accepts keyword list as client" do
      response = Bunnyx.Factory.video_response()

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/library/90001/videos/abc", _opts ->
        {:ok, response}
      end)

      assert {:ok, %Bunnyx.Stream.Video{}} =
               Bunnyx.Stream.get([api_key: "lib-key", library_id: 90_001], "abc")
    end
  end
end
