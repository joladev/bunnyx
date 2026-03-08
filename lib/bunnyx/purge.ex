defmodule Bunnyx.Purge do
  @moduledoc """
  Cache purging. When you update content at your origin, the CDN keeps serving the
  old cached version until it expires. Purging forces edge servers to fetch the new
  version immediately.

  You can purge a single URL or an entire pull zone's cache. Uses the main API client
  created with `Bunnyx.new/1`.

  ## Usage

      client = Bunnyx.new(api_key: "sk-...")

      {:ok, nil} = Bunnyx.Purge.url(client, "https://example.com/image.png")
      {:ok, nil} = Bunnyx.Purge.url(client, "https://example.com/", async: true, exact_path: true)
      {:ok, nil} = Bunnyx.Purge.pull_zone(client, 12345)
      {:ok, nil} = Bunnyx.Purge.pull_zone(client, 12345, cache_tag: "images")
  """

  @doc """
  Purges a URL from the CDN cache.

  ## Options

    * `:async` — perform the purge asynchronously
    * `:exact_path` — only purge the exact URL (no wildcard)

  """
  @spec url(Bunnyx.t() | keyword(), String.t(), keyword()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def url(client, url, opts \\ []) do
    client = Bunnyx.resolve(client)
    params = build_params(url, opts)

    case Bunnyx.HTTP.request(client.req, :post, "/purge", params: params) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc """
  Purges an entire pull zone's cache.

  ## Options

    * `:cache_tag` — only purge items with this cache tag

  """
  @spec pull_zone(Bunnyx.t() | keyword(), pos_integer(), keyword()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def pull_zone(client, id, opts \\ []) do
    client = Bunnyx.resolve(client)

    req_opts =
      case Keyword.fetch(opts, :cache_tag) do
        {:ok, tag} -> [json: %{"CacheTag" => tag}]
        :error -> []
      end

    case Bunnyx.HTTP.request(client.req, :post, "/pullzone/#{id}/purgeCache", req_opts) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  defp build_params(url, opts) do
    mapping = %{async: "async", exact_path: "exactPath"}

    params = %{"url" => url}

    Enum.reduce(opts, params, fn {key, value}, acc ->
      Map.put(acc, Map.fetch!(mapping, key), value)
    end)
  end
end
