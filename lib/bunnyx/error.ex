defmodule Bunnyx.Error do
  @moduledoc "Error struct returned by all Bunnyx API calls."

  @type t :: %__MODULE__{
          status: pos_integer() | nil,
          message: String.t(),
          errors: [map()] | nil
        }

  defstruct [:status, :message, :errors]
end
