defmodule Bunnyx.HTTP do
  @moduledoc """
  Low-level HTTP layer. All API modules go through `request/4` — they never
  call Req directly. You shouldn't need to use this module unless you're
  extending Bunnyx with unsupported endpoints.
  """

  @type method :: :get | :head | :post | :put | :patch | :delete

  @doc """
  Performs an HTTP request against the bunny.net API.

  ## Options

  In addition to standard Req options (`:body`, `:json`, `:params`, `:headers`),
  the following Bunnyx-specific options are supported:

    * `:return_headers` — return `{:ok, {body, headers}}` instead of `{:ok, body}`
    * `:receive_timeout` — per-request receive timeout in milliseconds

  HEAD requests always return headers only.
  """
  @spec request(Req.Request.t(), method(), String.t(), keyword()) ::
          {:ok, term()} | {:error, Bunnyx.Error.t()}
  def request(req, method, path, opts \\ []) do
    {return_headers, opts} = Keyword.pop(opts, :return_headers, false)
    {timeout, req_opts} = Keyword.pop(opts, :receive_timeout)

    req_opts = [{:method, method}, {:url, path} | req_opts]
    req_opts = if timeout, do: [{:receive_timeout, timeout} | req_opts], else: req_opts

    case Req.request(req, req_opts) do
      {:ok, %Req.Response{status: status} = response} when status in 200..299 ->
        cond do
          method == :head -> {:ok, response.headers}
          return_headers -> {:ok, {response.body, response.headers}}
          true -> {:ok, response.body}
        end

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error,
         %Bunnyx.Error{
           status: status,
           message: extract_message(body),
           errors: extract_errors(body)
         }}

      {:error, exception} ->
        {:error, %Bunnyx.Error{message: sanitize(Exception.message(exception))}}
    end
  end

  defp extract_message(%{"Message" => message}) when is_binary(message), do: message
  defp extract_message(body) when is_binary(body), do: body
  defp extract_message(_), do: "Unknown error"

  defp extract_errors(%{"Errors" => errors}) when is_list(errors), do: errors
  defp extract_errors(_), do: nil

  defp sanitize(message) do
    message
    |> String.replace(~r/AccessKey:\s*\S+/, "AccessKey: [REDACTED]")
    |> String.replace(~r/api_key=\S+/, "api_key=[REDACTED]")
  end
end
