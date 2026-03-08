# Bunnyx

[![CI](https://github.com/joladev/bunnyx/actions/workflows/ci.yml/badge.svg)](https://github.com/joladev/bunnyx/actions/workflows/ci.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/bunnyx.svg)](https://hex.pm/packages/bunnyx)
[![Docs](https://img.shields.io/badge/docs-hexdocs-blue.svg)](https://hexdocs.pm/bunnyx)

Elixir client for the [bunny.net](https://bunny.net) CDN API. Built on [Req](https://github.com/wojtekmach/req).

bunny.net is a content delivery platform — CDN, edge storage, DNS, and cache management.
Bunnyx wraps their REST API so you can manage these resources from Elixir.

## Installation

```elixir
def deps do
  [
    {:bunnyx, "~> 0.1.0"}
  ]
end
```

## Quick start

Bunnyx has two clients because bunny.net uses two separate services with different
auth and endpoints:

- `Bunnyx.new/1` — for the main API (pull zones, DNS, purging). Uses your account API key.
- `Bunnyx.Storage.new/1` — for edge storage. Uses a per-zone storage password.

```elixir
# Main API client — pull zones, DNS, cache purging
client = Bunnyx.new(api_key: "sk-...")

# Storage client — file uploads and downloads
storage = Bunnyx.Storage.new(storage_key: "pw-...", zone: "my-zone")
```

All functions return `{:ok, result}` or `{:error, %Bunnyx.Error{}}`. Responses come
back as typed structs, not raw maps.

## Usage

### Pull zones

Pull zones are bunny.net's CDN distribution points. Each zone pulls content from your
origin server and caches it across their edge network.

```elixir
{:ok, page} = Bunnyx.PullZone.list(client)
{:ok, zone} = Bunnyx.PullZone.create(client, name: "my-zone", origin_url: "https://example.com")
{:ok, zone} = Bunnyx.PullZone.get(client, zone.id)
{:ok, zone} = Bunnyx.PullZone.update(client, zone.id, cache_control_max_age_override: 3600)
{:ok, nil}  = Bunnyx.PullZone.delete(client, zone.id)
```

### Edge storage

Edge storage lets you store and serve files directly from bunny.net's network, without
needing your own origin server.

```elixir
{:ok, objects} = Bunnyx.Storage.list(storage, "/images/")
{:ok, binary}  = Bunnyx.Storage.get(storage, "/images/logo.png")
{:ok, nil}     = Bunnyx.Storage.put(storage, "/images/new.png", data)
{:ok, nil}     = Bunnyx.Storage.delete(storage, "/images/old.png")
```

### Cache purging

When you update content at your origin, you need to purge the CDN cache so edge servers
fetch the new version.

```elixir
{:ok, nil} = Bunnyx.Purge.url(client, "https://cdn.example.com/image.png")
{:ok, nil} = Bunnyx.Purge.pull_zone(client, 12345)
```

### DNS

bunny.net can also host your DNS. Zones hold your domain's records.

```elixir
{:ok, zone} = Bunnyx.DnsZone.create(client, domain: "example.com")
{:ok, zone} = Bunnyx.DnsZone.get(client, zone.id)

{:ok, record} = Bunnyx.DnsRecord.add(client, zone.id,
  type: 0,
  name: "www",
  value: "1.2.3.4",
  ttl: 300
)

{:ok, record} = Bunnyx.DnsRecord.update(client, zone.id, record.id, ttl: 600)
{:ok, nil}    = Bunnyx.DnsRecord.delete(client, zone.id, record.id)
```

### One-off calls

Every function also accepts a keyword list instead of a client struct. This creates
a throwaway client for a single request — convenient for scripts, less so for
production code where you'd reuse a client.

```elixir
{:ok, zones} = Bunnyx.PullZone.list(api_key: "sk-...")
```

## Error handling

All functions return `{:ok, result}` or `{:error, %Bunnyx.Error{}}`. The error struct
has a `status` field (HTTP status code, or `nil` for network errors) and a `message`.

```elixir
case Bunnyx.PullZone.get(client, 999) do
  {:ok, zone} -> zone
  {:error, %Bunnyx.Error{status: 404}} -> nil
  {:error, error} -> raise "API error: #{error.message}"
end
```

## Design

- **No global state.** No `Application.get_env`, no compile-time config. Credentials are passed explicitly. This means you can use multiple bunny.net accounts in the same app and tests don't share state.
- **Built on Req.** No custom HTTP layer. Req handles retries, compression, JSON, and connection pooling through Finch.
- **Typed structs.** API responses are parsed into structs with snake_case fields, not left as raw PascalCase maps.

## License

MIT — see [LICENSE](LICENSE).
