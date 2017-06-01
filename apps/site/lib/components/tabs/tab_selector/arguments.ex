defmodule Site.Components.Tabs.TabSelector do
  @moduledoc """
  Component for tab selection.
  """

  defstruct [
    id: "tab-select",
    class: "",
    links: [{"Schedule", Site.Router.Helpers.schedule_path(Site.Endpoint, :show, :bus)}],
    selected: "Schedule",
    full_width?: true,
    icon_map: %{},
    buttonbar: false
  ]

  @type t :: %__MODULE__{
    id: String.t,
    class: String.t,
    links: [%{title: String.t, href: String.t, icon: Phoenix.HTML.safe | nil, selected?: boolean}],
    buttonbar: boolean
  }

  def selected?(title, title), do: true
  def selected?(_, _), do: false

  def non_selected_links(links, selected) do
    Enum.reject(links, fn {title, _} -> title == selected end)
  end
end
