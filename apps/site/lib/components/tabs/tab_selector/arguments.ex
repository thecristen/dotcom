defmodule Site.Components.Tabs.TabSelector do
  @moduledoc """
  Component for tab selection. Elements collapse at the given `collapse` breakpoint
  """

  defstruct [
    id: "tab-select",
    class: "",
    links: [{"Schedule", Site.Router.Helpers.schedule_path(Site.Endpoint, :show, :bus)}],
    collapse: nil,
    selected: "Schedule",
    full_width?: true,
    icon_map: %{},
    buttonbar: false
  ]

  @type t :: %__MODULE__{
    id: String.t,
    class: String.t,
    links: [%{title: String.t, href: String.t, icon: Phoenix.HTML.Safe.t | nil, selected?: boolean}],
    collapse: String.t | nil,
    buttonbar: boolean
  }

  def selected?(title, title), do: true
  def selected?(_, _), do: false

  def small_screen_class("xs"), do: "hidden-sm-up"
  def small_screen_class("sm"), do: "hidden-md-up"
  def small_screen_class(_collapse), do: ""

  def large_screen_class("xs"), do: "hidden-xs-down"
  def large_screen_class("sm"), do: "hidden-sm-down"
  def large_screen_class(_collapse), do: ""

  def non_selected_links(links, selected) do
    Enum.reject(links, fn {title, _} -> title == selected end)
  end
end
