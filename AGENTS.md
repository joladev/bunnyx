# AGENTS.md

Bunnyx is an Elixir client library for the bunny.net API.

## Architecture

```
Bunnyx.new/1         → %Bunnyx{req: %Req.Request{}}       (main API)
Bunnyx.Storage.new/1 → %Bunnyx.Storage{req: ..., zone: ...}  (edge storage)
Bunnyx.S3.new/1      → %Bunnyx.S3{req: ..., zone: ...}       (S3-compatible storage)
Bunnyx.Stream.new/1  → %Bunnyx.Stream{req: ..., library_id: ...} (video streaming)
                              ↓
              Bunnyx.HTTP.request/4  (single HTTP entry point)
                              ↓
              Req → {:ok, result} | {:error, %Bunnyx.Error{}}
```

### Clients

Four client types because bunny.net uses different auth and base URLs:

| Client | Auth | Base URL | Modules |
|--------|------|----------|---------|
| `Bunnyx` | Account API key | `api.bunny.net` | PullZone, DnsZone, StorageZone, VideoLibrary, Shield, EdgeScript, MagicContainers, Purge, Statistics, Billing, Account, ApiKey, Logging, Country, Region |
| `Bunnyx.Storage` | Storage zone password | `storage.bunnycdn.com` | File upload/download/delete/list |
| `Bunnyx.S3` | Zone name + password (SigV4) | `{region}-s3.storage.bunnycdn.com` | S3-compatible ops + multipart |
| `Bunnyx.Stream` | Library API key | `video.bunnycdn.com` | Video CRUD, collections, captions |

### Core modules

- `Bunnyx.HTTP` — single HTTP entry point. Emits telemetry events. Handles error extraction, sanitization.
- `Bunnyx.Error` — universal error struct with `status`, `message`, `method`, `path`, `errors`.
- `Bunnyx.Params` — shared helpers for key mapping (`map_keys!/2`) and validation.
- `Bunnyx.S3.XML` — XML parsing for S3 responses using Erlang's `:xmerl` (XXE-safe).

### Response conventions

- Main API (PullZone, DnsZone, etc.) uses PascalCase responses.
- Stream API uses camelCase responses.
- Shield API wraps responses in `{data, page, error}` — unwrapped internally.
- Some list endpoints return flat lists, others return paginated wrappers. All `list` functions handle both.

## Conventions

- No global state. No `Application.get_env`, no compile-time config.
- All public functions return `{:ok, result}` or `{:error, %Bunnyx.Error{}}`.
- Create/update functions accept keyword lists with snake_case keys, converted via `Bunnyx.Params.map_keys!/2`.
- Unknown keys in attrs raise `ArgumentError` with valid keys listed.
- Client structs derive `Inspect` excluding `:req` to prevent API key leakage.
- Response structs with secrets (StorageZone, VideoLibrary) derive `Inspect` excluding sensitive fields.
- Error struct derives `Inspect` showing only `:status`, `:message`, `:method`, `:path`.

## Testing

- Mock `Bunnyx.HTTP` (via Mimic) when testing API modules.
- Mock `Req` (via Mimic) when testing `Bunnyx.HTTP` itself.
- Factory functions in `test/support/factory.ex`.
- All tests run `async: true`.
- **Mimic + default args gotcha**: always call `Bunnyx.HTTP.request/4` with all 4 arguments (pass `[]` explicitly).

### Integration testing

`livebooks/integration.livemd` runs against the real bunny.net API. Requires a `LB_BUNNY_API_KEY` env var. Covers Storage Zone, Pull Zone, DNS, Video Library, and Stream lifecycles.

## Quality checks

All must pass before committing:

```
mix compile --warnings-as-errors
mix test
mix format --check-formatted
mix credo --strict
```
