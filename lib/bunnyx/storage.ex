defmodule Bunnyx.Storage do
  @moduledoc """
  Edge storage lets you store and serve files directly from bunny.net's network,
  without needing your own origin server.

  Storage uses a **separate client** from the main API because it has its own
  authentication (a per-zone storage password) and a different base URL.
  Create one with `Bunnyx.Storage.new/1`.

  ## Usage

      client = Bunnyx.Storage.new(storage_key: "pw-...", zone: "my-zone")

      {:ok, objects} = Bunnyx.Storage.list(client, "/images/")
      {:ok, binary} = Bunnyx.Storage.get(client, "/images/logo.png")
      {:ok, nil} = Bunnyx.Storage.put(client, "/images/new.png", data)
      {:ok, nil} = Bunnyx.Storage.delete(client, "/images/old.png")

  For storage zones in a specific region, pass the `:region` option:

      client = Bunnyx.Storage.new(storage_key: "pw-...", zone: "my-zone", region: "de")
  """

  alias Bunnyx.Storage.Object

  @type t :: %__MODULE__{req: Req.Request.t(), zone: String.t()}

  @derive {Inspect, except: [:req]}
  @enforce_keys [:req, :zone]
  defstruct [:req, :zone]

  @doc """
  Creates a new storage client.

  ## Options

    * `:storage_key` (required) — your storage zone password
    * `:zone` (required) — the storage zone name
    * `:region` — storage region (e.g. `"de"`, `"ny"`). Defaults to the primary region.
    * `:receive_timeout` — socket receive timeout in milliseconds (default `15_000`)
    * `:finch` — a custom Finch pool name

  """
  @spec new(keyword()) :: t()
  def new(opts) do
    storage_key = Keyword.fetch!(opts, :storage_key)
    zone = Keyword.fetch!(opts, :zone)
    region = Keyword.get(opts, :region)

    base_url =
      case region do
        nil -> "https://storage.bunnycdn.com"
        r -> "https://#{r}.storage.bunnycdn.com"
      end

    req_opts =
      [base_url: base_url, headers: [{"AccessKey", storage_key}]]
      |> maybe_put(:receive_timeout, opts[:receive_timeout])
      |> maybe_put(:finch, opts[:finch])

    %__MODULE__{req: Req.new(req_opts), zone: zone}
  end

  @doc false
  @spec resolve(t() | keyword()) :: t()
  def resolve(%__MODULE__{} = client), do: client
  def resolve(opts) when is_list(opts), do: new(opts)

  @doc "Lists files and directories at the given path."
  @spec list(t() | keyword(), String.t()) ::
          {:ok, [Object.t()]} | {:error, Bunnyx.Error.t()}
  def list(client, path \\ "/") do
    client = resolve(client)
    full_path = build_path(client.zone, ensure_trailing_slash(path))

    case Bunnyx.HTTP.request(client.req, :get, full_path, []) do
      {:ok, body} -> {:ok, Enum.map(body, &Object.from_response/1)}
      {:error, _} = error -> error
    end
  end

  @doc "Downloads a file and returns its binary content."
  @spec get(t() | keyword(), String.t()) ::
          {:ok, binary()} | {:error, Bunnyx.Error.t()}
  def get(client, path) do
    client = resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, build_path(client.zone, path), []) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc """
  Uploads a file.

  ## Options

    * `:checksum` — SHA-256 checksum for integrity verification

  """
  @spec put(t() | keyword(), String.t(), binary(), keyword()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def put(client, path, data, opts \\ []) do
    client = resolve(client)

    req_opts = maybe_put([body: data], :headers, checksum_header(opts))

    case Bunnyx.HTTP.request(client.req, :put, build_path(client.zone, path), req_opts) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Deletes a file."
  @spec delete(t() | keyword(), String.t()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def delete(client, path) do
    client = resolve(client)

    case Bunnyx.HTTP.request(client.req, :delete, build_path(client.zone, path), []) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  defp build_path(zone, "/" <> _ = path), do: "/#{zone}#{path}"
  defp build_path(zone, path), do: "/#{zone}/#{path}"

  defp ensure_trailing_slash(path) do
    if String.ends_with?(path, "/"), do: path, else: path <> "/"
  end

  defp checksum_header(opts) do
    case Keyword.fetch(opts, :checksum) do
      {:ok, checksum} -> [{"Checksum", checksum}]
      :error -> nil
    end
  end

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)
end
