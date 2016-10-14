defmodule News.Post do
  defstruct [:id, :attributes, :body]
  @type t :: %__MODULE__{
    id: String.t,
    attributes: %{String.t => String.t},
    body: String.t
  }
end
