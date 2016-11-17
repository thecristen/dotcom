defmodule Site.Components.Buttons.ModeButton do
  @moduledoc """

  The is the documentation for a button.

  """
  import Site.ViewHelpers

  defstruct class:           nil,
            id:              nil,
            alert:           nil,
            route:           %{id: "CR-Fitchburg", key_route?: false, name: "Fitchburg Line", type: 2}

  def variants do
    [
      {
        "Mode Button with Alert",
        %Site.Components.Buttons.ModeButton{
          route: List.last(Routes.Repo.all),
          alert: List.first(Alerts.Repo.all)
        }
      },
      {
        "Subway Mode Button (includes color circle)",
        %Site.Components.Buttons.ModeButton{
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
end
