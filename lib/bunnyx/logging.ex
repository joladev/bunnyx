defmodule Bunnyx.Logging do
  @moduledoc """
  CDN access logs and origin error logs.

  CDN logs are raw pipe-separated text with one line per request. Origin error
  logs are JSON with structured error data.

  Both use separate base URLs from the main API but authenticate with the same
  account API key.

  ## Usage

      client = Bunnyx.new(api_key: "sk-...")

      {:ok, log_text} = Bunnyx.Logging.cdn(client, 12345, ~D[2025-06-01])
      {:ok, errors} = Bunnyx.Logging.origin_errors(client, 12345, ~D[2025-06-01])
  """

  @cdn_base_url "https://logging.bunnycdn.com"
  @origin_base_url "https://cdn-origin-logging.bunny.net"

  @doc """
  Downloads CDN access logs for a pull zone on a given date.

  Returns raw pipe-separated log text. Logs have a 3-day retention window.

  The date can be a `Date` struct or a string in `"MM-DD-YY"` format.
  """
  @spec cdn(Bunnyx.t() | keyword(), pos_integer(), Date.t() | String.t()) ::
          {:ok, String.t()} | {:error, Bunnyx.Error.t()}
  def cdn(client, pull_zone_id, date) do
    client = Bunnyx.resolve(client)
    date_str = format_cdn_date(date)

    req = override_base_url(client.req, @cdn_base_url)

    case Bunnyx.HTTP.request(req, :get, "/#{date_str}/#{pull_zone_id}.log", []) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc """
  Downloads origin error logs for a pull zone on a given date.

  Returns parsed JSON with structured error data.

  The date can be a `Date` struct or a string in `"MM-dd-yyyy"` format.
  """
  @spec origin_errors(Bunnyx.t() | keyword(), pos_integer(), Date.t() | String.t()) ::
          {:ok, term()} | {:error, Bunnyx.Error.t()}
  def origin_errors(client, pull_zone_id, date) do
    client = Bunnyx.resolve(client)
    date_str = format_origin_date(date)

    req = override_base_url(client.req, @origin_base_url)

    case Bunnyx.HTTP.request(req, :get, "/#{pull_zone_id}/#{date_str}", []) do
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  defp override_base_url(req, base_url) do
    %{req | options: Map.put(req.options, :base_url, base_url)}
  end

  defp format_cdn_date(%Date{} = date), do: Calendar.strftime(date, "%m-%d-%y")
  defp format_cdn_date(date) when is_binary(date), do: date

  defp format_origin_date(%Date{} = date), do: Calendar.strftime(date, "%m-%d-%Y")
  defp format_origin_date(date) when is_binary(date), do: date
end
