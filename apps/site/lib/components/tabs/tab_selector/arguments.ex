defmodule Site.Components.Tabs.TabSelector do
  @moduledoc """
  Component for tab selection. Elements collapse at tge given `collapse` breakpoint
  """

  defstruct [
    id: "tab-select",
    class: "",
    links: [{"Schedule", Site.Router.Helpers.schedule_path(Site.Endpoint, :show, :bus)}],
    collapse: nil,
    selected: "Schedule",
    full_width?: true,
    icon_map: %{}
  ]

  @type t :: %__MODULE__{
    id: String.t,
    class: String.t,
    links: [%{title: String.t, href: String.t, icon: Phoenix.HTML.Safe.t | nil, selected?: boolean}],
    collapse: String.t | nil
  }

  def selected?(title, title), do: true
  def selected?(_, _), do: false

  def btn_class("xs"), do: "hidden-sm-up"
  def btn_class("sm"), do: "hidden-md-up"
  def btn_class(_collapse), do: ""

  def nav_class("xs"), do: "collapse tab-toggleable-xs"
  def nav_class("sm"), do: "collapse tab-toggleable-sm"
  def nav_class(_collapse), do: ""
end
