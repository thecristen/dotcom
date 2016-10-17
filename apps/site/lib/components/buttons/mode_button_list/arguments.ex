defmodule Site.Components.Buttons.ModeButtonList do
  defstruct class:     nil,
            id:        nil,
            routes:    [
              %{id: "CR-Fitchburg", key_route?: false, name: "Fitchburg Line", type: 2},
              %{id: "CR-Worcester", key_route?: false, name: "Framingham/Worcester Line", type: 2}
            ],
            alerts:    []

  def get_alert(route, alerts) do
    entity = %Alerts.InformedEntity{route_type: route.type, route: route.id}
    alerts
    |> Enum.reject(&Alerts.Alert.is_notice?/1)
    |> Alerts.Match.match(entity)
  end

end
