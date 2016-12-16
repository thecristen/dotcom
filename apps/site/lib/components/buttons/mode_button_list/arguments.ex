defmodule Site.Components.Buttons.ModeButtonList do
  @moduledoc """

  The is the documentation for a button list.

  """

  import Phoenix.HTML.Link, only: [link: 2]
  import Phoenix.HTML.Tag, only: [content_tag: 3]

  defstruct class:     "",
            id:        nil,
            routes:    [
              %{id: "CR-Fitchburg", key_route?: false, name: "Fitchburg Line", type: 2},
              %{id: "CR-Worcester", key_route?: false, name: "Framingham/Worcester Line", type: 2}
            ],
            alerts:    [],
            date: nil,
            include_all_link: false

  @type t :: %__MODULE__{
    class: String.t,
    id: String.t | nil,
    routes: [Routes.Route.t],
    alerts: [Alerts.Alert.t],
    date: Date.t | nil,
    include_all_link: boolean
  }

  def get_alert(route, alerts, date) do
    date = date || Util.now()
    entity = %Alerts.InformedEntity{route_type: route.type, route: route.id}
    alerts
    |> Enum.find(nil, fn alert ->
      (not Alerts.Alert.is_notice?(alert, date)) &&
        Alerts.Match.match([alert], entity, date) == [alert]
    end)
  end

  def all_link([%{type: type}|_]) when type in [0,1] do
    path = Site.Router.Helpers.mode_path(Site.Endpoint, :subway)
    link to: path do
      [
        "View all subway ",
        arrow_text("lines")
      ]
    end
  end

  def all_link([%{type: 2}|_]) do
    path = Site.Router.Helpers.mode_path(Site.Endpoint, :commuter_rail)
    link to: path do
      [
        "View all commuter rail ",
        arrow_text("lines")
      ]
    end
  end

  def all_link([%{type: 3}|_]) do
    path = Site.Router.Helpers.mode_path(Site.Endpoint, :bus)
    link to: path do
      [
        "View all bus ",
        arrow_text("routes")
      ]
    end
    end

  def all_link([%{type: 4}|_]) do
    path = Site.Router.Helpers.mode_path(Site.Endpoint, :ferry)
    link to: path do
      [
        "View all ferry ",
        arrow_text("routes")
      ]
    end
  end

  defp arrow_text(text) do
    content_tag :span, [
      text,
      ' ',
      content_tag(:i, "", class: "fa fa-arrow-right")
    ], class: "no-wrap"
  end
end
