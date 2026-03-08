# Bunnyx

[![CI](https://github.com/joladev/bunnyx/actions/workflows/ci.yml/badge.svg)](https://github.com/joladev/bunnyx/actions/workflows/ci.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/bunnyx.svg)](https://hex.pm/packages/bunnyx)
[![Docs](https://img.shields.io/badge/docs-hexdocs-blue.svg)](https://hexdocs.pm/bunnyx)

Elixir client for the [bunny.net](https://bunny.net) CDN API. Built on [Req](https://github.com/wojtekmach/req).

## Installation

```elixir
def deps do
  [
    {:bunnyx, "~> 0.1.0"}
  ]
end
```

## Usage

### Pull Zones

```elixir
client = Bunnyx.new(api_key: "sk-...")

{:ok, page} = Bunnyx.PullZone.list(client)
{:ok, zone} = Bunnyx.PullZone.get(client, 12345)
{:ok, zone} = Bunnyx.PullZone.create(client, name: "my-zone", origin_url: "https://example.com")
{:ok, zone} = Bunnyx.PullZone.update(client, zone.id, cache_control_max_age_override: 3600)
{:ok, nil}  = Bunnyx.PullZone.delete(client, zone.id)
```

### Edge Storage

```elixir
storage = Bunnyx.Storage.new(storage_key: "pw-...", zone: "my-zone")

{:ok, objects} = Bunnyx.Storage.list(storage, "/images/")
{:ok, binary}  = Bunnyx.Storage.get(storage, "/images/logo.png")
{:ok, nil}     = Bunnyx.Storage.put(storage, "/images/new.png", data)
{:ok, nil}     = Bunnyx.Storage.delete(storage, "/images/old.png")
```

### Cache Purging

```elixir
{:ok, nil} = Bunnyx.Purge.url(client, "https://cdn.example.com/image.png")
{:ok, nil} = Bunnyx.Purge.pull_zone(client, 12345)
```

### DNS

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

Every function also accepts a keyword list instead of a client struct:

```elixir
{:ok, zones} = Bunnyx.PullZone.list(api_key: "sk-...")
```

## Error handling

All functions return `{:ok, result}` or `{:error, %Bunnyx.Error{}}`:

```elixir
case Bunnyx.PullZone.get(client, 999) do
  {:ok, zone} -> zone
  {:error, %Bunnyx.Error{status: 404}} -> nil
  {:error, error} -> raise "API error: #{error.message}"
end
```

## License

MIT — see [LICENSE](LICENSE).
