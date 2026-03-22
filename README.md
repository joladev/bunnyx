# Bunnyx

[![CI](https://github.com/joladev/bunnyx/actions/workflows/ci.yml/badge.svg)](https://github.com/joladev/bunnyx/actions/workflows/ci.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/bunnyx.svg)](https://hex.pm/packages/bunnyx)
[![Docs](https://img.shields.io/badge/docs-hexdocs-blue.svg)](https://hexdocs.pm/bunnyx)

Elixir client for the [bunny.net](https://bunny.net) API. Built on [Req](https://github.com/wojtekmach/req).

Covers the full bunny.net platform — CDN, edge storage, S3-compatible storage, DNS,
video streaming, Shield/WAF, edge scripting, magic containers, billing, and more.

## Installation

```elixir
def deps do
  [
    {:bunnyx, "~> 0.1.0"}
  ]
end
```

## Quick start

Most of the API uses a single client authenticated with your account API key.
Edge storage and video streaming use separate clients with their own credentials —
see [Clients](#clients) below.

```elixir
client = Bunnyx.new(api_key: "sk-...")

# CDN
{:ok, zone} = Bunnyx.PullZone.create(client, name: "my-zone", origin_url: "https://example.com")
{:ok, zone} = Bunnyx.PullZone.get(client, zone.id)

# DNS
{:ok, dns} = Bunnyx.DnsZone.create(client, domain: "example.com")
{:ok, record} = Bunnyx.DnsRecord.add(client, dns.id, type: 0, name: "www", value: "1.2.3.4", ttl: 300)

# Storage zone management
{:ok, sz} = Bunnyx.StorageZone.create(client, name: "my-storage", region: "DE")

# Purge
{:ok, nil} = Bunnyx.Purge.pull_zone(client, zone.id)
```

## Clients

bunny.net uses different authentication for different services. Bunnyx provides four
client types:

| Client | Auth | Use for |
|--------|------|---------|
| `Bunnyx.new/1` | Account API key | CDN, DNS, storage zones, video libraries, Shield, billing, and everything else |
| `Bunnyx.Storage.new/1` | Storage zone password | File upload, download, delete, list |
| `Bunnyx.S3.new/1` | Zone name + password (SigV4) | S3-compatible storage with multipart uploads |
| `Bunnyx.Stream.new/1` | Library API key | Video CRUD, upload, collections, captions |

```elixir
# Edge storage — upload and download files
storage = Bunnyx.Storage.new(storage_key: "pw-...", zone: "my-zone")
{:ok, nil} = Bunnyx.Storage.put(storage, "/images/logo.png", image_data)
{:ok, data} = Bunnyx.Storage.get(storage, "/images/logo.png")

# S3-compatible storage
s3 = Bunnyx.S3.new(zone: "my-zone", storage_key: "pw-...", region: "de")
{:ok, nil} = Bunnyx.S3.put(s3, "file.txt", "hello")
{:ok, result} = Bunnyx.S3.list(s3, prefix: "images/")

# Video streaming
stream = Bunnyx.Stream.new(api_key: "lib-key-...", library_id: 12345)
{:ok, video} = Bunnyx.Stream.create(stream, title: "My Video")
{:ok, nil} = Bunnyx.Stream.upload(stream, video.guid, video_binary)
```

## API coverage

### Main API (`Bunnyx.new/1`)

- **CDN**: `PullZone` (CRUD, hostnames, SSL, edge rules, referrers, IP blocking, statistics)
- **DNS**: `DnsZone` (CRUD, DNSSEC, export/import, statistics), `DnsRecord` (add, update, delete)
- **Storage management**: `StorageZone` (CRUD, statistics, password reset)
- **Video libraries**: `VideoLibrary` (CRUD, API keys, watermarks, referrers, DRM stats)
- **Cache**: `Purge` (URL and pull zone purging)
- **Security**: `Shield` (zones, WAF rules, rate limiting, access lists, bot detection, metrics, API Guardian)
- **Compute**: `EdgeScript` (scripts, code, releases, secrets, variables), `MagicContainers` (apps, registries, containers, endpoints, volumes)
- **Account**: `Billing` (details, summary, invoices), `Account` (affiliate, audit log, search), `ApiKey`, `Logging` (CDN + origin logs)
- **Reference**: `Statistics` (global), `Country`, `Region`

### Separate clients

- **Edge storage** (`Bunnyx.Storage`): upload, download, delete, list files
- **S3** (`Bunnyx.S3`): PUT, GET, DELETE, HEAD, COPY, ListObjectsV2, multipart uploads
- **Stream** (`Bunnyx.Stream`): video CRUD, upload, fetch, collections, captions, thumbnails, re-encode, transcription, smart actions, analytics, oEmbed

## Error handling

All functions return `{:ok, result}` or `{:error, %Bunnyx.Error{}}`. Errors include
the HTTP method and path for debugging:

```elixir
case Bunnyx.PullZone.get(client, 999) do
  {:ok, zone} -> zone
  {:error, %Bunnyx.Error{status: 404}} -> nil
  {:error, error} -> raise "#{error.method} #{error.path}: #{error.message}"
end
```

## Telemetry

Bunnyx emits telemetry events for every HTTP request:

- `[:bunnyx, :request, :start]` — before the request
- `[:bunnyx, :request, :stop]` — after a response (success or error status)
- `[:bunnyx, :request, :exception]` — on transport errors (timeouts, connection failures)

## Design

- **No global state.** Credentials are passed explicitly. Multiple accounts work in the same app.
- **Built on Req.** Retries, compression, JSON, connection pooling via Finch.
- **Typed structs.** API responses are parsed into structs with snake_case fields.
- **Secure by default.** Client structs hide credentials in `inspect`. Error messages sanitize API keys.
- **Configurable.** Per-request timeouts, custom Req options via `:req_opts`.

## Integration testing

An integration Livebook at `livebooks/integration.livemd` tests the SDK against the
real bunny.net API. Set `LB_BUNNY_API_KEY` and run all cells.

## License

MIT — see [LICENSE](LICENSE).
