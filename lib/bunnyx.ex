defmodule Bunnyx do
  @moduledoc """
  Elixir client for the bunny.net API.

  ## Which client do I need?

  bunny.net has several services with different authentication and base URLs.
  Each gets its own client:

  | Client | Auth | Use for |
  |--------|------|---------|
  | `Bunnyx.new/1` | Account API key | CDN, DNS, storage zones, video libraries, billing, shield, edge scripting, magic containers |
  | `Bunnyx.Storage.new/1` | Storage zone password | File upload/download/delete in edge storage |
  | `Bunnyx.S3.new/1` | Zone name + password (SigV4) | S3-compatible storage operations |
  | `Bunnyx.Stream.new/1` | Library API key | Video CRUD, upload, collections, captions |

  Most users only need `Bunnyx.new/1`. Use the others when working directly with
  files (Storage/S3) or videos (Stream).

  ## Creating a client

      client = Bunnyx.new(api_key: "sk-...")

  The client holds a configured `Req.Request` struct. Reuse it across calls to
  share the connection pool:

      {:ok, zones} = Bunnyx.PullZone.list(client)
      {:ok, zone}  = Bunnyx.PullZone.get(client, 12345)

  For one-off calls, you can pass options directly — a throwaway client is created:

      {:ok, zones} = Bunnyx.PullZone.list(api_key: "sk-...")

  ## Error handling

  All functions return `{:ok, result}` or `{:error, %Bunnyx.Error{}}`. The error
  struct includes the HTTP status code (or `nil` for network errors) and a message.

  ## Main API modules (use `Bunnyx.new/1`)

    * `Bunnyx.PullZone` — CDN pull zones and edge rules
    * `Bunnyx.DnsZone` — DNS zones, DNSSEC, export/import
    * `Bunnyx.DnsRecord` — DNS records within a zone
    * `Bunnyx.StorageZone` — storage zone management
    * `Bunnyx.VideoLibrary` — Stream video library management
    * `Bunnyx.Purge` — cache invalidation
    * `Bunnyx.Statistics` — account-wide statistics
    * `Bunnyx.Shield` — WAF, rate limiting, bot detection, access lists
    * `Bunnyx.EdgeScript` — edge scripting (code, releases, secrets, variables)
    * `Bunnyx.MagicContainers` — containerized apps at the edge
    * `Bunnyx.Billing` — billing details and invoices
    * `Bunnyx.Account` — affiliate, audit log, search
    * `Bunnyx.Logging` — CDN access logs and origin error logs
    * `Bunnyx.ApiKey` — API key listing
    * `Bunnyx.Country` — country list for geo-blocking
    * `Bunnyx.Region` — edge region list

  ## Separate client modules

    * `Bunnyx.Storage` — edge storage file operations (own auth + base URL)
    * `Bunnyx.S3` — S3-compatible storage with AWS SigV4 signing
    * `Bunnyx.Stream` — video CRUD, upload, collections, captions (own auth + base URL)
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
