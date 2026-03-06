defmodule Bunnyx.HTTP do
  @moduledoc "Generic HTTP wrapper for bunny.net API calls."

  @type method :: :get | :post | :put | :delete

  @spec request(Req.Request.t(), method(), String.t(), keyword()) ::
          {:ok, term()} | {:error, Bunnyx.Error.t()}
  def request(req, method, path, opts \\ []) do
    {body, opts} = Keyword.pop(opts, :body)
    {params, opts} = Keyword.pop(opts, :params)

    req_opts =
      [{:method, method}, {:url, path} | opts]
      |> maybe_put(:json, body)
      |> maybe_put(:params, params)

    case Req.request(req, req_opts) do
      {:ok, %Req.Response{status: status, body: body}} when status in 200..299 ->
        {:ok, body}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error,
         %Bunnyx.Error{
           status: status,
           message: extract_message(body),
           errors: extract_errors(body)
         }}

      {:error, exception} ->
        {:error, %Bunnyx.Error{message: Exception.message(exception)}}
    end
  end

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)

  defp extract_message(%{"Message" => message}) when is_binary(message), do: message
  defp extract_message(body) when is_binary(body), do: body
  defp extract_message(_), do: "Unknown error"

  defp extract_errors(%{"Errors" => errors}) when is_list(errors), do: errors
  defp extract_errors(_), do: nil
end
