defmodule Site.OldSiteRedirectController do
  use Site.Web, :controller
  import Site.Router.Helpers
  import Site.ViewHelpers, only: [cms_static_page_path: 2]
  alias Site.ControllerHelpers

  @s3_files ["feed_info.txt", "MBTA_GTFS.zip"]

  def schedules_and_maps(conn, %{"route" => route}) do
    case old_route_to_route_id(route) do
      nil -> old_site_redirect(conn)
      route_id -> redirect conn, to: schedule_path(conn, :show, route_id)
    end
  end
  def schedules_and_maps(conn, %{"path" => [_mode, "lines", "stations" | _], "stopId" => stop_id}) do
    case Stops.Repo.old_id_to_gtfs_id(stop_id) do
      nil ->  old_site_redirect(conn)
      gtfs_id -> redirect conn, to: stop_path(conn, :show, gtfs_id)
    end
  end
  def schedules_and_maps(conn, %{"path" => [mode, "lines", "stations" | _]}) do
    redirect_mode = case mode do
      "rail" -> :commuter_rail
      "boats" -> :ferry
      _ -> :subway
    end
    redirect conn, to: stop_path(conn, :show, redirect_mode)
  end
  def schedules_and_maps(conn, %{"path" => ["rail" | _]}) do
    redirect conn, to: mode_path(conn, :commuter_rail)
  end
  def schedules_and_maps(conn, %{"path" => ["boats" | _]}) do
    redirect conn, to: mode_path(conn, :ferry)
  end
  def schedules_and_maps(conn, %{"path" => ["subway" | _]}) do
    redirect conn, to: mode_path(conn, :subway)
  end
  def schedules_and_maps(conn, %{"path" => ["bus" | _]}) do
    redirect conn, to: mode_path(conn, :bus)
  end
  def schedules_and_maps(conn, %{"path" => ["system_map" | _]}) do
    redirect conn, to: cms_static_page_path(conn, "/maps")
  end
  def schedules_and_maps(conn, params) when params == %{} do
    redirect conn, to: mode_path(conn, :index)
  end
  def schedules_and_maps(conn, _params) do
    old_site_redirect(conn)
  end

  def archived_files(conn, _params) do
    ControllerHelpers.forward_static_file(conn, s3_file_url("archive/archived_feeds.txt"))
  end

  def uploaded_files(conn, %{"path" => [file_name]}) when file_name in @s3_files do
    ControllerHelpers.forward_static_file(conn, s3_file_url(file_name))
  end
  def uploaded_files(conn, _params) do
    ControllerHelpers.forward_static_file(conn, old_site_file_url(conn.request_path))
  end

  defp old_site_file_url(request_path) do
    host = :site |> Application.get_env(:former_mbta_site) |> Keyword.get(:host)
    "#{host}#{request_path}"
  end

  defp s3_file_url(file_name) do
    bucket_name = bucket_name(Application.get_env(:site, OldSiteRedirectController)[:gtfs_s3_bucket])
    "https://s3.amazonaws.com/#{bucket_name}/#{URI.encode(file_name)}"
  end

  defp bucket_name({:system, env_var, default}) do
    if value = System.get_env(env_var), do: value, else: default
  end

  defp old_site_redirect(conn) do
    redirect conn, to: redirect_path(conn, :show, conn.path_info, conn.query_params)
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
  defp old_route_to_route_id("SL1"), do: "741"
  defp old_route_to_route_id("SL2"), do: "742"
  defp old_route_to_route_id("SL4"), do: "751"
  defp old_route_to_route_id("SL5"), do: "749"
  defp old_route_to_route_id("CT1"), do: "701"
  defp old_route_to_route_id("CT2"), do: "747"
  defp old_route_to_route_id("CT3"), do: "708"
  defp old_route_to_route_id("34E"), do: "34E"
  defp old_route_to_route_id("77A"), do: "77A"
  defp old_route_to_route_id("57A"), do: "57A"
  defp old_route_to_route_id("70A"), do: "70A"
  defp old_route_to_route_id(route) do
    case Integer.parse(route) do
      {route_id, ""} -> route_id
      _ -> nil
    end
  end
end
