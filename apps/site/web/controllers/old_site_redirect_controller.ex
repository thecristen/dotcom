defmodule Site.OldSiteRedirectController do
  use Site.Web, :controller
  import Site.Router.Helpers

  def index(conn, _params) do
    old_site_redirect(conn, page_url(conn, :index))
  end

  def schedules_and_maps(conn, %{"route" => route}) do
    url = case old_route_to_route_id(route) do
            nil -> mode_url(conn, :index)
            route_id -> schedule_url(conn, :show, route_id)
          end
    old_site_redirect(conn, url)
  end
  def schedules_and_maps(conn, %{"path" => ["rail" | _]}) do
    old_site_redirect(conn, mode_url(conn, :commuter_rail))
  end
  def schedules_and_maps(conn, %{"path" => ["boats" | _]}) do
    old_site_redirect(conn, mode_url(conn, :ferry))
  end
  def schedules_and_maps(conn, %{"path" => ["subway" | _]}) do
    old_site_redirect(conn, mode_url(conn, :subway))
  end
  def schedules_and_maps(conn, %{"path" => ["bus" | _]}) do
    old_site_redirect(conn, mode_url(conn, :bus))
  end
  def schedules_and_maps(conn, _params) do
    old_site_redirect(conn, mode_url(conn, :index))
  end

  def realtime_subway(conn, _params) do
    old_site_redirect(conn, mode_url(conn, :subway))
  end

  def fares_and_passes(conn, %{"path" => ["rail" | _]}) do
    old_site_redirect(conn, fare_url(conn, :show, :commuter_rail))
  end
  def fares_and_passes(conn, %{"path" => ["subway" | _]}) do
    old_site_redirect(conn, fare_url(conn, :show, :bus_subway))
  end
  def fares_and_passes(conn, %{"path" => ["bus" | _]}) do
    old_site_redirect(conn, fare_url(conn, :show, :bus_subway))
  end
  def fares_and_passes(conn, %{"path" => ["boats" | _]}) do
    old_site_redirect(conn, fare_url(conn, :show, :ferry))
  end
  def fares_and_passes(conn, %{"path" => ["passes" | _]}) do
    old_site_redirect(conn, fare_url(conn, :show, :bus_subway, filter: "passes"))
  end
  def fares_and_passes(conn, %{"path" => ["charlie" | _]}) do
    old_site_redirect(conn, fare_url(conn, :show, :charlie_card))
  end
  def fares_and_passes(conn, _params) do
    old_site_redirect(conn, fare_url(conn, :index))
  end

  def uploaded_files(conn, %{"path" => path_parts}) do
    full_url = "http://www2.mbta.com/uploadedfiles/#{path_parts |> Enum.map(&URI.encode/1) |> Enum.join("/")}"
    params = conn.query_params
    with {:ok, response} <- HTTPoison.get(full_url, [], params: params),
         %{status_code: 200, headers: headers, body: body} <- response do
      headers
      |> Enum.reduce(conn, fn {header, value}, conn ->
        put_resp_header(conn, String.downcase(header), value)
      end)
      |> send_resp(200, body)
    else
      _ ->
        conn
        |> put_status(:not_found)
        |> render(Site.ErrorView, "404.html", [])
        |> halt
    end
  end

  defp old_site_redirect(conn, url) do
    redirect(conn, external: url)
  end

  defp old_route_to_route_id("RED"), do: "Red"
  defp old_route_to_route_id("GREEN"), do: "Green"
  defp old_route_to_route_id("BLUE"), do: "Blue"
  defp old_route_to_route_id("ORANGE"), do: "Orange"
  defp old_route_to_route_id("SILVER"), do: "741" # SL1
  defp old_route_to_route_id("FAIRMNT"), do: "CR-Fairmount"
  defp old_route_to_route_id("FITCHBRG"), do: "CR-Fitchburg"
  defp old_route_to_route_id("WORCSTER"), do: "CR-Worcester"
  defp old_route_to_route_id("FRANKLIN"), do: "CR-Franklin"
  defp old_route_to_route_id("GREENBSH"), do: "CR-Greenbush"
  defp old_route_to_route_id("HAVRHILL"), do: "CR-Haverhill"
  defp old_route_to_route_id("KINGSTON"), do: "CR-Kingston"
  defp old_route_to_route_id("LOWELL"), do: "CR-Lowell"
  defp old_route_to_route_id("MIDLBORO"), do: "CR-Middleborough"
  defp old_route_to_route_id("NEEDHAM"), do: "CR-Needham"
  defp old_route_to_route_id("NBRYROCK"), do: "CR-Newburyport"
  defp old_route_to_route_id("PROVSTOU"), do: "CR-Providence"
  defp old_route_to_route_id("F1"), do: "Boat-F1"
  defp old_route_to_route_id("F2"), do: "Boat-F3"
  defp old_route_to_route_id("F4"), do: "Boat-F4"
  defp old_route_to_route_id(_), do: nil
end
