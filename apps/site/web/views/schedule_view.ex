defmodule Site.ScheduleView do
  use Site.Web, :view

  def svg(_conn, path) do
    svg_content = :site
    |> Application.app_dir
    |> Path.join("priv/static" <> path)
    |> File.read!
    |> String.split("\n")
    |> Enum.drop(1) # drop the <?xml> header
    |> Enum.join("")

    raw svg_content
  end

  def has_alerts?(alerts, schedule) do
    entity = %Alerts.InformedEntity{
      route_type: schedule.route.type,
      route: schedule.route.id,
      stop: schedule.stop.id
    }

    Alerts.Match.match(alerts, entity, schedule.time) != []
  end

  def hidden_query_params(conn, opts \\ []) do
    exclude = Keyword.get(opts, :exclude, [])
    conn.params
    |> Enum.reject(fn {key, _} -> key in exclude end)
    |> Enum.map(&hidden_tag/1)
  end

  defp hidden_tag({key, value}) do
    tag :input, type: "hidden", name: key, value: value
  end

end
