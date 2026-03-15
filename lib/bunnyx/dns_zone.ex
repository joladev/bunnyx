defmodule Bunnyx.DnsZone do
  @moduledoc """
  DNS zones. bunny.net can host your domain's DNS alongside its CDN. A zone
  represents a domain and contains DNS records managed through `Bunnyx.DnsRecord`.

  Uses the main API client created with `Bunnyx.new/1`.

  ## Usage

      client = Bunnyx.new(api_key: "sk-...")

      {:ok, zone} = Bunnyx.DnsZone.create(client, domain: "example.com")
      {:ok, zone} = Bunnyx.DnsZone.get(client, zone.id)
      {:ok, page} = Bunnyx.DnsZone.list(client)
      {:ok, zone} = Bunnyx.DnsZone.update(client, zone.id, logging_enabled: true)
      {:ok, nil} = Bunnyx.DnsZone.delete(client, zone.id)

  Fetching a zone with `get/2` includes its records as a list of `%Bunnyx.DnsRecord{}`
  structs in the `:records` field.
  """

  alias Bunnyx.DnsRecord

  @type t :: %__MODULE__{
          id: pos_integer() | nil,
          domain: String.t() | nil,
          records: [DnsRecord.t()] | nil,
          date_modified: String.t() | nil,
          date_created: String.t() | nil,
          nameservers_detected: boolean() | nil,
          custom_nameservers_enabled: boolean() | nil,
          nameserver1: String.t() | nil,
          nameserver2: String.t() | nil,
          soa_email: String.t() | nil,
          nameservers_next_check: String.t() | nil,
          logging_enabled: boolean() | nil,
          logging_ip_anonymization_enabled: boolean() | nil,
          log_anonymization_type: integer() | nil,
          dns_sec_enabled: boolean() | nil,
          certificate_key_type: integer() | nil
        }

  defstruct [
    :id,
    :domain,
    :records,
    :date_modified,
    :date_created,
    :nameservers_detected,
    :custom_nameservers_enabled,
    :nameserver1,
    :nameserver2,
    :soa_email,
    :nameservers_next_check,
    :logging_enabled,
    :logging_ip_anonymization_enabled,
    :log_anonymization_type,
    :dns_sec_enabled,
    :certificate_key_type
  ]

  @field_mapping %{
    "Id" => :id,
    "Domain" => :domain,
    "Records" => :records,
    "DateModified" => :date_modified,
    "DateCreated" => :date_created,
    "NameserversDetected" => :nameservers_detected,
    "CustomNameserversEnabled" => :custom_nameservers_enabled,
    "Nameserver1" => :nameserver1,
    "Nameserver2" => :nameserver2,
    "SoaEmail" => :soa_email,
    "NameserversNextCheck" => :nameservers_next_check,
    "LoggingEnabled" => :logging_enabled,
    "LoggingIPAnonymizationEnabled" => :logging_ip_anonymization_enabled,
    "LogAnonymizationType" => :log_anonymization_type,
    "DnsSecEnabled" => :dns_sec_enabled,
    "CertificateKeyType" => :certificate_key_type
  }

  @reverse_mapping Map.new(@field_mapping, fn {pascal, atom} -> {atom, pascal} end)

  @doc """
  Lists DNS zones.

  ## Options

    * `:page` — page number
    * `:per_page` — items per page
    * `:search` — search term

  """
  @spec list(Bunnyx.t() | keyword(), keyword()) ::
          {:ok,
           %{
             items: [t()],
             current_page: integer(),
             total_items: integer(),
             has_more_items: boolean()
           }}
          | {:error, Bunnyx.Error.t()}
  def list(client, opts \\ []) do
    client = Bunnyx.resolve(client)

    params =
      opts
      |> Keyword.take([:page, :per_page, :search])
      |> to_query_params()

    case Bunnyx.HTTP.request(client.req, :get, "/dnszone", params: params) do
      {:ok, body} ->
        {:ok,
         %{
           items: Enum.map(body["Items"], &from_response/1),
           current_page: body["CurrentPage"],
           total_items: body["TotalItems"],
           has_more_items: body["HasMoreItems"]
         }}

      {:error, _} = error ->
        error
    end
  end

  @doc "Fetches a DNS zone by ID, including its records."
  @spec get(Bunnyx.t() | keyword(), pos_integer()) :: {:ok, t()} | {:error, Bunnyx.Error.t()}
  def get(client, id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/dnszone/#{id}", []) do
      {:ok, body} -> {:ok, from_response(body)}
      {:error, _} = error -> error
    end
  end

  @doc "Creates a DNS zone with the given attributes."
  @spec create(Bunnyx.t() | keyword(), keyword()) :: {:ok, t()} | {:error, Bunnyx.Error.t()}
  def create(client, attrs) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/dnszone", json: to_request_body(attrs)) do
      {:ok, body} -> {:ok, from_response(body)}
      {:error, _} = error -> error
    end
  end

  @doc "Updates a DNS zone."
  @spec update(Bunnyx.t() | keyword(), pos_integer(), keyword()) ::
          {:ok, t()} | {:error, Bunnyx.Error.t()}
  def update(client, id, attrs) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/dnszone/#{id}", json: to_request_body(attrs)) do
      {:ok, body} -> {:ok, from_response(body)}
      {:error, _} = error -> error
    end
  end

  @doc "Deletes a DNS zone."
  @spec delete(Bunnyx.t() | keyword(), pos_integer()) :: {:ok, nil} | {:error, Bunnyx.Error.t()}
  def delete(client, id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :delete, "/dnszone/#{id}", []) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Enables DNSSEC for a DNS zone."
  @spec enable_dnssec(Bunnyx.t() | keyword(), pos_integer()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def enable_dnssec(client, id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/dnszone/#{id}/dnssec", []) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Disables DNSSEC for a DNS zone."
  @spec disable_dnssec(Bunnyx.t() | keyword(), pos_integer()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def disable_dnssec(client, id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :delete, "/dnszone/#{id}/dnssec", []) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  @doc "Exports a DNS zone as a BIND-format zone file."
  @spec export(Bunnyx.t() | keyword(), pos_integer()) ::
          {:ok, String.t()} | {:error, Bunnyx.Error.t()}
  def export(client, id) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/dnszone/#{id}/export", []) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc "Imports DNS records from a BIND-format zone file."
  @spec import_records(Bunnyx.t() | keyword(), pos_integer(), String.t()) ::
          {:ok,
           %{
             records_successful: integer(),
             records_failed: integer(),
             records_skipped: integer()
           }}
          | {:error, Bunnyx.Error.t()}
  def import_records(client, id, zone_data) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/dnszone/#{id}/import", body: zone_data) do
      {:ok, body} ->
        {:ok,
         %{
           records_successful: body["RecordsSuccessful"],
           records_failed: body["RecordsFailed"],
           records_skipped: body["RecordsSkipped"]
         }}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Returns DNS zone query statistics.

  ## Options

    * `:date_from` — start date (ISO 8601 string)
    * `:date_to` — end date (ISO 8601 string)

  """
  @spec statistics(Bunnyx.t() | keyword(), pos_integer(), keyword()) ::
          {:ok,
           %{
             total_queries_served: integer(),
             queries_served_chart: map(),
             normal_queries_served_chart: map(),
             smart_queries_served_chart: map(),
             queries_by_type_chart: map()
           }}
          | {:error, Bunnyx.Error.t()}
  def statistics(client, id, opts \\ []) do
    client = Bunnyx.resolve(client)

    params =
      opts
      |> Keyword.take([:date_from, :date_to])
      |> to_statistics_params()

    case Bunnyx.HTTP.request(client.req, :get, "/dnszone/#{id}/statistics", params: params) do
      {:ok, body} ->
        {:ok,
         %{
           total_queries_served: body["TotalQueriesServed"],
           queries_served_chart: body["QueriesServedChart"],
           normal_queries_served_chart: body["NormalQueriesServedChart"],
           smart_queries_served_chart: body["SmartQueriesServedChart"],
           queries_by_type_chart: body["QueriesByTypeChart"]
         }}

      {:error, _} = error ->
        error
    end
  end

  @doc "Checks if a DNS zone name is available."
  @spec check_availability(Bunnyx.t() | keyword(), String.t()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def check_availability(client, name) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :post, "/dnszone/checkavailability",
           json: %{"Name" => name}
         ) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  defp from_response(data) when is_map(data) do
    fields =
      for {pascal, atom} <- @field_mapping, Map.has_key?(data, pascal), into: %{} do
        value = data[pascal]

        case atom do
          :records when is_list(value) -> {:records, Enum.map(value, &DnsRecord.from_response/1)}
          _ -> {atom, value}
        end
      end

    struct(__MODULE__, fields)
  end

  defp to_request_body(attrs) do
    Map.new(attrs, fn {key, value} ->
      pascal = Map.fetch!(@reverse_mapping, key)
      {pascal, value}
    end)
  end

  defp to_statistics_params(opts) do
    mapping = %{date_from: "dateFrom", date_to: "dateTo"}

    Map.new(opts, fn {key, value} ->
      {Map.fetch!(mapping, key), value}
    end)
  end

  defp to_query_params(opts) do
    mapping = %{page: "page", per_page: "perPage", search: "search"}

    Map.new(opts, fn {key, value} ->
      {Map.fetch!(mapping, key), value}
    end)
  end
end
