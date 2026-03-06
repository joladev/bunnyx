defmodule Bunnyx.Storage do
  @moduledoc """
  Edge Storage API.

  ## Usage

      client = Bunnyx.Storage.new(storage_key: "pw-...", zone: "my-zone")

      {:ok, objects} = Bunnyx.Storage.list(client, "/images/")
      {:ok, binary} = Bunnyx.Storage.get(client, "/images/logo.png")
      {:ok, nil} = Bunnyx.Storage.put(client, "/images/new.png", data)
      {:ok, nil} = Bunnyx.Storage.delete(client, "/images/old.png")
  """

  alias Bunnyx.Storage.Object

  @type t :: %__MODULE__{req: Req.Request.t(), zone: String.t()}

  @enforce_keys [:req, :zone]
  defstruct [:req, :zone]

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
      maybe_put(
        [base_url: base_url, headers: [{"AccessKey", storage_key}]],
        :finch,
        opts[:finch]
      )

    %__MODULE__{req: Req.new(req_opts), zone: zone}
  end

  @doc false
  @spec resolve(t() | keyword()) :: t()
  def resolve(%__MODULE__{} = client), do: client
  def resolve(opts) when is_list(opts), do: new(opts)

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

  @spec get(t() | keyword(), String.t()) ::
          {:ok, binary()} | {:error, Bunnyx.Error.t()}
  def get(client, path) do
    client = resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, build_path(client.zone, path), []) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

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
