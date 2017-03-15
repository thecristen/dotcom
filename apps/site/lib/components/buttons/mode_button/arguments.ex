defmodule Site.Components.Buttons.ModeButton do
  @moduledoc """

  The is the documentation for a button.

  """
  import Site.ViewHelpers
  import Site.Router.Helpers, only: [schedule_path: 3]
  alias Site.Components.Buttons.ModeButton
  alias Phoenix.HTML.Tag

  defstruct class:           "",
            id:              nil,
            conn:            Site.Endpoint, # not a conn but works in the link helpers
            alert:           nil,
            route:           %{id: "CR-Fitchburg", key_route?: false, name: "Fitchburg Line", type: 2}

  @type t :: %__MODULE__{
    class: String.t,
    id: String.t | nil,
    alert: Alerts.Alert.t,
    route: Routes.Route.t
  }

  def variants do
    [
      {
        "Mode Button with Alert",
        %ModeButton{
          route: List.last(Routes.Repo.all),
          alert: List.first(Alerts.Repo.all)
        }
      },
      {
        "Subway Mode Button (includes color circle)",
        %ModeButton{
          route: List.first(Routes.Repo.all)
        }
      }
    ]

  end

  def subway_color_icon(%{type: 0, name: name}), do: do_subway_color_icon(name)
  def subway_color_icon(%{type: 1, name: name}), do: do_subway_color_icon(name)
  def subway_color_icon(_), do: ""

  defp do_subway_color_icon(name) do
    name |> clean_route_name |> String.downcase |> render_subway_color_icon
  end

  defp render_subway_color_icon(name), do: fa("circle fa-color-subway-#{name}")

  def has_alert?(nil), do: false
  def has_alert?([]), do: false
  def has_alert?(_), do: true

  def link_tag(args) do
    Tag.tag :a, class: "mode-group-btn #{args.class}", id: args.id, href: schedule_path(args.conn, :show, args.route.id)
  end
end
