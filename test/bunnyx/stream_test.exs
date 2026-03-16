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

      Bunnyx.Stream.list(client, page: 2, items_per_page: 10, search: "test")
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
  end

  describe "delete/2" do
    test "returns {:ok, nil}", %{client: client} do
      expect(Bunnyx.HTTP, :request, fn _req, :delete, "/library/90001/videos/abc-123", _opts ->
        {:ok, ""}
      end)

      assert {:ok, nil} = Bunnyx.Stream.delete(client, "abc-123")
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
