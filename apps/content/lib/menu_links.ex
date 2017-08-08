defmodule Content.MenuLinks do
  @moduledoc """
  Represents a "Menu Links" content type in the Drupal CMS.
  """

  import Content.Helpers, only: [field_value: 2]

  defstruct [title: "", links: []]

  @type t :: %__MODULE__{
    title: String.t,
    links: [Content.Field.Link.t]
  }

  @spec from_api(map) :: t
  def from_api(%{"type" => [%{"target_id" => "menu_links"}]} = data) do
    %__MODULE__{
      title: field_value(data, "title"),
      links: Enum.map(data["field_links"], & Content.Field.Link.from_api(&1))
    }
  end
end
