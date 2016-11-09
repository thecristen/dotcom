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

  def rewrite_static_files(%Content.Page{body: body} = page) when is_binary(body) do
    static_path = Content.Config.static_path
    new_body = Regex.replace(~r/"(#{static_path}[^"]+)"/, body, fn _, path ->
      ['"', Content.Config.apply(:static, [path]), '"']
    end)
    %{page | body: new_body}
  end
  def rewrite_static_files(%Content.Page{} = page), do: page
end
