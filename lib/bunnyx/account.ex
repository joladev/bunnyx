defmodule Bunnyx.Account do
  @moduledoc """
  Account-level operations — affiliate details, audit logs, global search,
  and account management.

  Uses the main API client created with `Bunnyx.new/1`.

  ## Usage

      client = Bunnyx.new(api_key: "sk-...")

      {:ok, affiliate} = Bunnyx.Account.affiliate(client)
      {:ok, logs} = Bunnyx.Account.audit_log(client, ~D[2025-06-01])
      {:ok, results} = Bunnyx.Account.search(client, "my-zone")
  """

  @doc "Returns affiliate program details and charts."
  @spec affiliate(Bunnyx.t() | keyword()) :: {:ok, map()} | {:error, Bunnyx.Error.t()}
  def affiliate(client) do
    client = Bunnyx.resolve(client)

    case Bunnyx.HTTP.request(client.req, :get, "/billing/affiliate", []) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc """
  Returns the user audit log for a given date.

  ## Options

    * `:product` — filter by product (list of strings)
    * `:resource_type` — filter by resource type (list of strings)
    * `:order` — `"Ascending"` or `"Descending"`
    * `:continuation_token` — pagination token
    * `:limit` — max results (1–10000)

  """
  @spec audit_log(Bunnyx.t() | keyword(), Date.t() | String.t(), keyword()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def audit_log(client, date, opts \\ []) do
    client = Bunnyx.resolve(client)
    date_str = format_date(date)
    params = to_audit_params(opts)

    case Bunnyx.HTTP.request(client.req, :get, "/user/audit/#{date_str}", params: params) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc """
  Searches across all resources.

  ## Options

    * `:from` — number of results to skip (default 0)
    * `:size` — number of results to return (default 20)

  """
  @spec search(Bunnyx.t() | keyword(), String.t(), keyword()) ::
          {:ok, map()} | {:error, Bunnyx.Error.t()}
  def search(client, query, opts \\ []) do
    client = Bunnyx.resolve(client)

    params =
      %{"search" => query}
      |> Bunnyx.Params.maybe_put_map("from", opts[:from])
      |> Bunnyx.Params.maybe_put_map("size", opts[:size])

    case Bunnyx.HTTP.request(client.req, :get, "/search", params: params) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc """
  Permanently closes the current user account.

  ## Options

    * `:password` — account password
    * `:reason` — reason for closing

  """
  @spec close_account(Bunnyx.t() | keyword(), keyword()) ::
          {:ok, nil} | {:error, Bunnyx.Error.t()}
  def close_account(client, opts \\ []) do
    client = Bunnyx.resolve(client)

    json =
      %{}
      |> Bunnyx.Params.maybe_put_map("Password", opts[:password])
      |> Bunnyx.Params.maybe_put_map("Reason", opts[:reason])

    case Bunnyx.HTTP.request(client.req, :post, "/user/closeaccount", json: json) do
      {:ok, _} -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  defp format_date(%Date{} = date), do: Calendar.strftime(date, "%Y-%m-%d")
  defp format_date(date) when is_binary(date), do: date

  defp to_audit_params(opts) do
    mapping = %{
      product: "Product",
      resource_type: "ResourceType",
      order: "Order",
      continuation_token: "ContinuationToken",
      limit: "Limit"
    }

    opts
    |> Keyword.take([:product, :resource_type, :order, :continuation_token, :limit])
    |> Map.new(fn {key, value} ->
      {Map.fetch!(mapping, key), value}
    end)
  end
end
