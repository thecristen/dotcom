defmodule Site.ScheduleView do
  use Site.Web, :view
  import Site.ScheduleView.Alerts

  def update_url(%{params: params} = conn, query) do
    query_map = query
    |> Enum.map(fn {key, value} -> {Atom.to_string(key), to_string(value)} end)
    |> Enum.into(%{})

    new_query = params
    |> Map.merge(query_map)
    |> Enum.into([])
    |> Enum.reject(&empty_value?/1)

    schedule_path(conn, :index, new_query)
  end

  @doc """
  Puts the conn into the assigns dictionary so that downstream templates can use it
  """
  def forward_assigns(%{assigns: assigns} = conn) do
    assigns
    |> Dict.put(:conn, conn)
  end
  def hidden_query_params(conn, opts \\ []) do
    exclude = Keyword.get(opts, :exclude, [])
    conn.params
    |> Enum.reject(fn {key, _} -> key in exclude end)
    |> Enum.map(&hidden_tag/1)
  end

  defp empty_value?({_, value}) do
    value in ["", nil]
  end

  defp hidden_tag({key, value}) do
    tag :input, type: "hidden", name: key, value: value
  end

  def newline_to_br(text) do
    import Phoenix.HTML

    text
    |> html_escape
    |> safe_to_string
    |> String.replace(~r/^(.*:)\s/, "<strong>\\1</strong>\n") # an initial header
    |> String.replace(~r/\n(.*:)\s/, "<hr><strong>\\1</strong>\n") # all other start with an HR
    |> String.replace(~r/\s*\n/s, "<br />")
    |> raw
  end

  @doc "Link a station's name to its page, if it exists. Otherwise, just returns the name."
  def station_name_as_link(station) do
    import Phoenix.HTML
    case Stations.Repo.get(station.id) do
      nil -> station.name
      _ -> link station.name, to: station_path(Site.Endpoint, :show, station.id)
    end
  end

  def station_info_link(station) do
    import Phoenix.HTML
    case Stations.Repo.get(station.id) do
      nil -> ""
      _ -> "(<a href='#{station_path(Site.Endpoint, :show, station.id)}'>View station info</a>)" |> raw
    end
  end


  def reverse_direction_opts(origin, dest, route_id, direction_id) do
    new_origin = dest || origin
    new_dest = dest && origin
    [trip: "", direction_id: direction_id, route: route_id]
    |> Keyword.merge(
      if Schedules.Repo.stop_exists_on_route?(new_origin, route_id, direction_id) do
        [dest: new_dest, origin: new_origin]
      else
        [dest: nil, origin: nil]
      end
    )
  end
end
