defmodule Content.BasicPage do
  @moduledoc """
  Represents a basic "page" type in the Drupal CMS.
  """

  import Content.Helpers, only: [field_value: 2, handle_html: 1]

  defstruct [id: "", title: "", body: {:safe, ""}]

  @type t :: %__MODULE__{
    id: String.t,
    title: String.t,
    body: Phoenix.HTML.Safe.t
  }

  @spec from_api(map) :: t
  def from_api(%{} = data) do
    %__MODULE__{
      id: field_value(data, "nid"),
      title: field_value(data, "title") || "",
      body: parse_body(data)
    }
  end

  defp parse_body(data) do
    data
    |> field_value("body")
    |> handle_html
  end
end
