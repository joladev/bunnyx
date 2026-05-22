defmodule Bunnyx.PullZone.Hostname do
  @moduledoc """
  A custom hostname attached to a pull zone, including SSL/cert state.

  Returned as part of `Bunnyx.PullZone.t().hostnames` from `Bunnyx.PullZone.get/2`.
  """

  @type t :: %__MODULE__{
          id: pos_integer() | nil,
          value: String.t() | nil,
          force_ssl: boolean() | nil,
          has_certificate: boolean() | nil
        }

  defstruct [:id, :value, :force_ssl, :has_certificate]

  @field_mapping %{
    "Id" => :id,
    "Value" => :value,
    "ForceSSL" => :force_ssl,
    "HasCertificate" => :has_certificate
  }

  @doc false
  @spec from_response(map()) :: t()
  def from_response(data) when is_map(data) do
    fields =
      for {pascal, atom} <- @field_mapping, Map.has_key?(data, pascal), into: %{} do
        {atom, data[pascal]}
      end

    struct(__MODULE__, fields)
  end
end
