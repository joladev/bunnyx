defmodule Bunnyx.DnsRecord do
  @moduledoc """
  DNS Record API.

  ## Usage

      client = Bunnyx.new(api_key: "sk-...")

      {:ok, record} = Bunnyx.DnsRecord.add(client, zone_id,
        type: 0,
        name: "www",
        value: "1.2.3.4",
        ttl: 300
      )

      {:ok, record} = Bunnyx.DnsRecord.update(client, zone_id, record.id, ttl: 600)
      {:ok, nil} = Bunnyx.DnsRecord.delete(client, zone_id, record.id)
  """

  @type t :: %__MODULE__{
          id: pos_integer() | nil,
          type: integer() | nil,
          ttl: integer() | nil,
          value: String.t() | nil,
          name: String.t() | nil,
          weight: integer() | nil,
          priority: integer() | nil,
          port: integer() | nil,
          flags: integer() | nil,
          tag: String.t() | nil,
          accelerated: boolean() | nil,
          disabled: boolean() | nil,
          comment: String.t() | nil
        }

  defstruct [
    :id,
    :type,
    :ttl,
    :value,
    :name,
    :weight,
    :priority,
    :port,
    :flags,
    :tag,
    :accelerated,
    :disabled,
    :comment
  ]

  @field_mapping %{
    "Id" => :id,
    "Type" => :type,
    "Ttl" => :ttl,
    "Value" => :value,
    "Name" => :name,
    "Weight" => :weight,
    "Priority" => :priority,
    "Port" => :port,
    "Flags" => :flags,
    "Tag" => :tag,
    "Accelerated" => :accelerated,
    "Disabled" => :disabled,
    "Comment" => :comment
  }

  @reverse_mapping Map.new(@field_mapping, fn {pascal, atom} -> {atom, pascal} end)

  @doc false
  def from_response(data) when is_map(data) do
    fields =
      for {pascal, atom} <- @field_mapping, Map.has_key?(data, pascal), into: %{} do
        {atom, data[pascal]}
      end

    struct(__MODULE__, fields)
  end

  @spec add(Bunnyx.t() | keyword(), pos_integer(), keyword()) ::
          {:ok, t()} | {:error, Bunnyx.Error.t()}
  def add(client, zone_id, attrs) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :put, "/dnszone/#{zone_id}/records",
           json: to_request_body(attrs)
         ) do
      {:ok, body} -> {:ok, from_response(body)}
      {:error, _} = error -> error
    end
  end

  @spec update(Bunnyx.t() | keyword(), pos_integer(), pos_integer(), keyword()) ::
          {:ok, t()} | {:error, Bunnyx.Error.t()}
  def update(client, zone_id, id, attrs) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/dnszone/#{zone_id}/records/#{id}",
           json: to_request_body(attrs)
         ) do
      {:ok, body} -> {:ok, from_response(body)}
      {:error, _} = error -> error
    end
  end

  @spec delete(Bunnyx.t() | keyword(), pos_integer(), pos_integer()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def delete(client, zone_id, id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :delete, "/dnszone/#{zone_id}/records/#{id}", []) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  defp to_request_body(attrs) do
    Map.new(attrs, fn {key, value} ->
      pascal = Map.fetch!(@reverse_mapping, key)
      {pascal, value}
    end)
  end
end
