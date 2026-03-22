defmodule Bunnyx.Error do
  @moduledoc """
  Error struct returned by all Bunnyx API calls.

  ## Fields

    * `:status` — HTTP status code (e.g. `404`, `500`). `nil` for network errors
      like connection timeouts where no HTTP response was received.
    * `:message` — human-readable error message from the bunny.net API, or a
      description of the transport error.
    * `:method` — the HTTP method of the failed request (e.g. `:get`, `:post`).
    * `:path` — the request path (e.g. `"/pullzone/123"`).
    * `:errors` — list of detailed validation errors from the API, if any.
  """

  @type t :: %__MODULE__{
          status: pos_integer() | nil,
          message: String.t(),
          method: atom() | nil,
          path: String.t() | nil,
          errors: [map()] | nil
        }

  @derive {Inspect, only: [:status, :message, :method, :path]}
  defstruct [:status, :message, :method, :path, :errors]
end
