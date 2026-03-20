defmodule Bunnyx do
  @moduledoc """
  Client for the bunny.net API.

  Bunnyx provides two clients because bunny.net has two separate services with different
  authentication and base URLs:

    * `Bunnyx.new/1` — main API client for pull zones, DNS, and cache purging.
      Authenticates with your account API key.
    * `Bunnyx.Storage.new/1` — edge storage client for file uploads and downloads.
      Authenticates with a per-zone storage password.

  ## Creating a client

      client = Bunnyx.new(api_key: "sk-...")

  The client holds a configured `Req.Request` struct. Reuse it across calls to share
  the connection pool:

      {:ok, zones} = Bunnyx.PullZone.list(client)
      {:ok, zone}  = Bunnyx.PullZone.get(client, 12345)

  For one-off calls (scripts, quick tests), you can skip the client and pass options
  directly — a throwaway client is created for the request:

      {:ok, zones} = Bunnyx.PullZone.list(api_key: "sk-...")

  ## Error handling

  All functions return `{:ok, result}` or `{:error, %Bunnyx.Error{}}`. The error
  struct includes the HTTP status code (or `nil` for network errors) and a message
  from the API.

  ## API modules

    * `Bunnyx.PullZone` — CDN distribution points
    * `Bunnyx.DnsZone` — DNS zone management
    * `Bunnyx.DnsRecord` — DNS records within a zone
    * `Bunnyx.Purge` — cache invalidation
    * `Bunnyx.Storage` — edge storage (separate client)
  """

  @type t :: %__MODULE__{req: Req.Request.t()}

  @derive {Inspect, except: [:req]}
  @enforce_keys [:req]
  defstruct [:req]

  @doc """
  Creates a new API client.

  ## Options

    * `:api_key` (required) — your bunny.net API key
    * `:receive_timeout` — default socket receive timeout in milliseconds
    * `:finch` — a custom Finch pool name
    * `:req_opts` — additional Req options merged into the request (e.g. `[redirect: false]`)

  ## Examples

      client = Bunnyx.new(api_key: "sk-...")

      # With custom timeout and Req options
      client = Bunnyx.new(api_key: "sk-...", receive_timeout: 30_000, req_opts: [retry: false])

  """
  @spec new(keyword()) :: t()
  def new(opts) do
    api_key = Keyword.fetch!(opts, :api_key)
    extra_req_opts = Keyword.get(opts, :req_opts, [])

    req_opts =
      [base_url: "https://api.bunny.net", headers: [{"AccessKey", api_key}]]
      |> maybe_put(:receive_timeout, opts[:receive_timeout])
      |> maybe_put(:finch, opts[:finch])
      |> Keyword.merge(extra_req_opts)

    %__MODULE__{req: Req.new(req_opts)}
  end

  @doc false
  @spec resolve(t() | keyword()) :: t()
  def resolve(%__MODULE__{} = client), do: client
  def resolve(opts) when is_list(opts), do: new(opts)

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)
end
