# Bunnyx

[![CI](https://github.com/joladev/bunnyx/actions/workflows/ci.yml/badge.svg)](https://github.com/joladev/bunnyx/actions/workflows/ci.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/bunnyx.svg)](https://hex.pm/packages/bunnyx)
[![Docs](https://img.shields.io/badge/docs-hexdocs-blue.svg)](https://hexdocs.pm/bunnyx)

Elixir client for the [bunny.net](https://bunny.net) API. Built on [Req](https://github.com/wojtekmach/req).

Covers the full bunny.net platform — CDN, edge storage, S3-compatible storage, DNS,
video streaming, Shield/WAF, edge scripting, magic containers, billing, and more.

- **Full typespecs** on every public function — Dialyzer-ready with IDE autocompletion
- **Typed structs** — responses parsed into structs with snake_case fields, not raw JSON
- **Runtime clients** — no `Application` config; pass credentials explicitly for easy multi-account and testing
- **Keyword lists with validation** — snake_case attrs, clear errors on typos
- **Documented** — `@moduledoc` and `@doc` with usage examples on every module and function

## Installation

```elixir
def deps do
  [
    {:bunnyx, "~> 0.2.0"}
  ]
end
```

## Quick start

Create a client and pass it to every call. No global config needed — multiple clients
with different credentials work side by side.

```elixir
client = Bunnyx.new(api_key: "sk-...")

# CDN — returns a %Bunnyx.PullZone{} struct
{:ok, zone} = Bunnyx.PullZone.create(client, name: "my-zone", origin_url: "https://example.com")
zone.id      #=> 12345
zone.name    #=> "my-zone"

# DNS
{:ok, dns} = Bunnyx.DnsZone.create(client, domain: "example.com")
{:ok, record} = Bunnyx.DnsRecord.add(client, dns.id, type: 0, name: "www", value: "1.2.3.4", ttl: 300)

# Typos fail fast
Bunnyx.PullZone.create(client, nme: "oops")
#=> ** (ArgumentError) unknown key :nme. Valid keys: :name, :origin_url, ...
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

## Design

Bunnyx follows Elixir library conventions — no compile-time config, no global state,
explicit clients.

- **Runtime clients, not Application config.** Every function takes a client struct.
  Multiple accounts work in the same BEAM. Tests don't need config stubs.
- **Built on Req.** Retries, compression, JSON, connection pooling via Finch — with
  per-request `:receive_timeout` and pass-through `:req_opts` for anything else.
- **Typed structs with typespecs.** Every public function has `@spec`. API responses
  are parsed into structs (`%PullZone{}`, `%DnsZone{}`, `%Video{}`, etc.) with
  snake_case fields — pattern match and dot-access instead of `body["CacheControlMaxAgeOverride"]`.
- **Validated keyword attrs.** Create/update functions accept keyword lists with
  snake_case keys, validated at call time. Unknown keys raise `ArgumentError` with
  the valid set listed.
- **Secure by default.** Client structs derive `Inspect` excluding credentials.
  Error messages sanitize API keys. Response structs with secrets (storage passwords,
  library API keys) hide sensitive fields.
- **Telemetry and observability.** Every HTTP request emits start/stop/exception events
  with method, path, status, and duration.

## Integration testing

The `livebooks/` directory contains per-domain integration tests that exercise every
SDK function against the real bunny.net API. Set `LB_BUNNY_API_KEY` and run the cells.

## License

MIT — see [LICENSE](LICENSE).
