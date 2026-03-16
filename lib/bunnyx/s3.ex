defmodule Bunnyx.S3 do
  @moduledoc """
  S3-compatible storage client for bunny.net. Uses AWS Signature V4 signing
  via Req's built-in `put_aws_sigv4` step — no additional dependencies.

  S3 must be **enabled at storage zone creation time** and cannot be toggled later.

  ## Usage

      client = Bunnyx.S3.new(zone: "my-zone", storage_key: "pw-...", region: "de")

      {:ok, nil} = Bunnyx.S3.put(client, "images/logo.png", image_data)
      {:ok, binary} = Bunnyx.S3.get(client, "images/logo.png")
      {:ok, headers} = Bunnyx.S3.head(client, "images/logo.png")
      {:ok, nil} = Bunnyx.S3.delete(client, "images/logo.png")
  """

  @type t :: %__MODULE__{req: Req.Request.t(), zone: String.t()}

  @enforce_keys [:req, :zone]
  defstruct [:req, :zone]

  @doc """
  Creates a new S3 client.

  ## Options

    * `:zone` (required) — storage zone name (also the S3 access key ID and bucket name)
    * `:storage_key` (required) — storage zone password (S3 secret access key)
    * `:region` (required) — `"de"`, `"ny"`, or `"sg"`
    * `:receive_timeout` — socket receive timeout in milliseconds (default `15_000`)
    * `:finch` — a custom Finch pool name

  """
  @spec new(keyword()) :: t()
  def new(opts) do
    zone = Keyword.fetch!(opts, :zone)
    storage_key = Keyword.fetch!(opts, :storage_key)
    region = Keyword.fetch!(opts, :region)

    base_url = "https://#{region}-s3.storage.bunnycdn.com"

    req_opts =
      [
        base_url: base_url,
        aws_sigv4: [
          service: :s3,
          access_key_id: zone,
          secret_access_key: storage_key,
          region: region
        ]
      ]
      |> maybe_put(:receive_timeout, opts[:receive_timeout])
      |> maybe_put(:finch, opts[:finch])

    %__MODULE__{req: Req.new(req_opts), zone: zone}
  end

  @doc false
  @spec resolve(t() | keyword()) :: t()
  def resolve(%__MODULE__{} = client), do: client
  def resolve(opts) when is_list(opts), do: new(opts)

  @doc """
  Uploads an object.

  ## Options

    * `:checksum` — SHA-256 checksum (Base64 encoded) for integrity verification

  """
  @spec put(t() | keyword(), String.t(), binary(), keyword()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def put(client, key, data, opts \\ []) do
    client = resolve(client)

    req_opts = maybe_put([body: data], :headers, checksum_header(opts))

    case Bunnyx.HTTP.request(client.req, :put, "/#{client.zone}/#{key}", req_opts) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc """
  Downloads an object.

  ## Options

    * `:range` — byte range string (e.g. `"bytes=0-1023"`)

  """
  @spec get(t() | keyword(), String.t(), keyword()) ::
          {:ok, binary()} | {:error, Bunnyx.Error.t()}
  def get(client, key, opts \\ []) do
    client = resolve(client)

    req_opts = maybe_put([], :headers, range_header(opts))

    case Bunnyx.HTTP.request(client.req, :get, "/#{client.zone}/#{key}", req_opts) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Deletes an object."
  @spec delete(t() | keyword(), String.t()) :: {:ok, nil} | {:error, Bunnyx.Error.t()}
  def delete(client, key) do
    client = resolve(client)

    case Bunnyx.HTTP.request(client.req, :delete, "/#{client.zone}/#{key}", []) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Returns object metadata (headers) without downloading the body."
  @spec head(t() | keyword(), String.t()) :: {:ok, map()} | {:error, Bunnyx.Error.t()}
  def head(client, key) do
    client = resolve(client)

    case Bunnyx.HTTP.request(client.req, :head, "/#{client.zone}/#{key}", []) do
      {:ok, headers} -> {:ok, headers}
      {:error, _} = error -> error
    end
  end

  defp checksum_header(opts) do
    case Keyword.fetch(opts, :checksum) do
      {:ok, checksum} -> [{"x-amz-checksum-sha256", checksum}]
      :error -> nil
    end
  end

  defp range_header(opts) do
    case Keyword.fetch(opts, :range) do
      {:ok, range} -> [{"range", range}]
      :error -> nil
    end
  end

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)
end
