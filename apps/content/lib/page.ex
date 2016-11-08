defmodule Content.Page.Missing do
  @doc "Represents a field value that wasn't loaded"
  defstruct [:field]
  @opaque t :: %__MODULE__{field: atom}
end

defmodule Content.Page do
  @moduledoc """

  A standalone page.

  """
  alias Content.Page.Missing

  @type t :: %__MODULE__{
    title: String.t,
    body: String.t,
    updated_at: DateTime.t
  }
  defstruct [
    title: %Missing{field: :title},
    body: %Missing{field: :body},
    updated_at: %Missing{field: :updated_at}
  ]
end
