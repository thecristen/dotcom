defmodule Content.Page.Missing do
  defstruct [:field]
end

defmodule Content.Page do
  @moduledoc """

  A standalone pagea

  """
  alias Content.Page.Missing

  defstruct [
    title: %Missing{field: :title},
    body: %Missing{field: :body},
    updated_at: %Missing{field: :updated_at}
  ]
end
