defmodule Content.Page do
  @moduledoc """

  A standalone page.

  """
  @type t :: %__MODULE__{
    title: String.t,
    body: String.t,
    updated_at: DateTime.t
  }
  defstruct [
    title: {:missing, :title},
    body: {:missing, :body},
    updated_at: {:missing, :updated_at}
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
