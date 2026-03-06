# AGENTS.md

Bunnyx is an Elixir client library for the bunny.net API. Design decisions are in `PLAN.md`.

## Architecture

```
Bunnyx.new/1 → %Bunnyx{req: %Req.Request{}}
                    ↓
API modules (PullZone, DNS, Purge, …) call Bunnyx.HTTP.request/4
                    ↓
Bunnyx.HTTP wraps Req, returns {:ok, result} | {:error, %Bunnyx.Error{}}
```

- `%Bunnyx{}` holds a pre-configured `%Req.Request{}` with base URL and auth header.
- `Bunnyx.resolve/1` lets API functions accept either a `%Bunnyx{}` struct or a keyword list.
- `Bunnyx.HTTP.request/4` is the single HTTP entry point. API modules never call Req directly.
- `Bunnyx.Error` is the one error struct for everything — HTTP errors, transport errors, API errors.
- API modules (e.g. `Bunnyx.PullZone`) are both the module and the struct. They own the field mapping between bunny.net PascalCase and Elixir snake_case.
- Storage will have its own struct (`%Bunnyx.Storage{}`) because it uses different auth and base URL.

## Conventions

- No global state. No `Application.get_env`, no compile-time config, no process dictionary tricks.
- All public functions return `{:ok, result}` or `{:error, %Bunnyx.Error{}}`. No bare atoms, no exceptions for expected errors.
- Fail fast. Use `Keyword.fetch!`, `Map.fetch!`, etc. No fallback values hiding bugs.
- Create/update functions accept keyword lists with snake_case keys, converted internally to PascalCase maps.

## Testing

- Mock `Bunnyx.HTTP` (via Mimic) when testing API modules.
- Mock `Req` (via Mimic) when testing `Bunnyx.HTTP` itself.
- Factory functions live in `test/support/factory.ex`.
- All tests run `async: true`.
- **Mimic + default args gotcha**: always call `Bunnyx.HTTP.request/4` with all 4 arguments (pass `[]` explicitly). Mimic cannot intercept the generated `/3` arity because it uses a local call to `/4`.

## Quality checks

All four must pass before committing:

```
mix compile --warnings-as-errors
mix test
mix format --check-formatted
mix credo --strict
```
