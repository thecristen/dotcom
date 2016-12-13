defmodule Site.Components.Buttons.ModeButtonList do
  @moduledoc """

  The is the documentation for a button list.

  """

  alias Phoenix.HTML.Tag

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

  def get_alert(route, alerts, date \\ nil) do
    date = date || Util.now()
    entity = %Alerts.InformedEntity{route_type: route.type, route: route.id}
    alerts
    |> Enum.reject(&Alerts.Alert.is_notice?(&1, date))
    |> Alerts.Match.match(entity, date)
    |> List.first
  end

  def all_link([%{type: type}|_]) when type in [0,1] do
    path = Site.Router.Helpers.mode_path(Site.Endpoint, :subway)
    ~s(<a href="#{path}">View all subway <span class="no-wrap">lines <i class="fa fa-arrow-right"></i></span></a>) |> Phoenix.HTML.raw
  end

  def all_link([%{type: 2}|_]) do
    path = Site.Router.Helpers.mode_path(Site.Endpoint, :commuter_rail)
    ~s(<a href="#{path}">View all commuter rail <span class="no-wrap">lines <i class="fa fa-arrow-right"></i></span></a>) |> Phoenix.HTML.raw
  end

  def all_link([%{type: 3}|_]) do
    path = Site.Router.Helpers.mode_path(Site.Endpoint, :bus)
    ~s(<a href="#{path}">View all bus <span class="no-wrap">routes <i class="fa fa-arrow-right"></i></span></a>) |> Phoenix.HTML.raw
    end

  def all_link([%{type: 4}|_]) do
    path = Site.Router.Helpers.mode_path(Site.Endpoint, :ferry)
    ~s(<a href="#{path}">View all ferry <span class="no-wrap">routes <i class="fa fa-arrow-right"></i></span></a>) |> Phoenix.HTML.raw
  end

  def opening_div(args) do
    Tag.tag :div, class: "mode-group-block #{args.class}", id: args.id
  end
end
