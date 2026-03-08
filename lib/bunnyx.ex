defmodule Bunnyx do
  @moduledoc """
  Client for the bunny.net API.

  ## Usage

      client = Bunnyx.new(api_key: "sk-...")
      {:ok, zones} = Bunnyx.PullZone.list(client)

  Or as a one-off:

      {:ok, zones} = Bunnyx.PullZone.list(api_key: "sk-...")
  """

  @type t :: %__MODULE__{req: Req.Request.t()}

  @enforce_keys [:req]
  defstruct [:req]

  @doc """
  Creates a new API client.

  ## Options

    * `:api_key` (required) — your bunny.net API key
    * `:finch` — a custom Finch pool name

  ## Examples

      client = Bunnyx.new(api_key: "sk-...")

  """
  @spec new(keyword()) :: t()
  def new(opts) do
    api_key = Keyword.fetch!(opts, :api_key)

    req_opts =
      maybe_put(
        [base_url: "https://api.bunny.net", headers: [{"AccessKey", api_key}]],
        :finch,
        opts[:finch]
      )

    %__MODULE__{req: Req.new(req_opts)}
  end

  @doc false
  @spec resolve(t() | keyword()) :: t()
  def resolve(%__MODULE__{} = client), do: client
  def resolve(opts) when is_list(opts), do: new(opts)

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)
end
