defmodule Bunnyx.HTTP do
  @moduledoc "Generic HTTP wrapper for bunny.net API calls."

  @type method :: :get | :post | :put | :delete

  @doc "Performs an HTTP request against the bunny.net API."
  @spec request(Req.Request.t(), method(), String.t(), keyword()) ::
          {:ok, term()} | {:error, Bunnyx.Error.t()}
  def request(req, method, path, opts \\ []) do
    req_opts = [{:method, method}, {:url, path} | opts]

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

  defp extract_message(%{"Message" => message}) when is_binary(message), do: message
  defp extract_message(body) when is_binary(body), do: body
  defp extract_message(_), do: "Unknown error"

  defp extract_errors(%{"Errors" => errors}) when is_list(errors), do: errors
  defp extract_errors(_), do: nil
end
