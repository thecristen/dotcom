defmodule Site.OldSiteRedirectController do
  use Site.Web, :controller
  import Site.Router.Helpers

  @s3_files ["feed_info.txt", "mbta_gtfs.zip"]

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
  def schedules_and_maps(conn, %{"path" => [_mode, "lines", "stations" | _], "stopId" => stop_id} = params) do
    case Stops.Repo.old_id_to_gtfs_id(stop_id) do
      nil ->  schedules_and_maps(conn, Map.delete(params, "stopId"))
      gtfs_id -> old_site_redirect(conn, stop_url(conn, :show, gtfs_id))
    end
  end
  def schedules_and_maps(conn, %{"path" => [mode, "lines", "stations" | _]}) do
    redirect_mode = case mode do
      "rail" -> :commuter_rail
      "boats" -> :ferry
      _ -> :subway
    end
    old_site_redirect(conn, stop_url(conn, :show, redirect_mode))
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

  def rider_tools(conn, %{"path" => ["realtime_subway" | _]}) do
    old_site_redirect(conn, mode_url(conn, :subway))
  end
  def rider_tools(conn, %{"path" => ["realtime_bus" | _]}) do
    old_site_redirect(conn, mode_url(conn, :bus))
  end
  def rider_tools(conn, %{"path" => ["servicenearby" | _]}) do
    old_site_redirect(conn, transit_near_me_url(conn, :index))
  end
  def rider_tools(conn, %{"path" => ["transit_updates" | _]}) do
    old_site_redirect(conn, alert_url(conn, :index))
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
    old_site_redirect(conn, fare_url(conn, :show, :payment_methods))
  end
  def fares_and_passes(conn, %{"path" => ["sales_locations" | _]}) do
    old_site_redirect(conn, fare_url(conn, :show, :retail_sales_locations))
  end
  def fares_and_passes(conn, %{"path" => ["reduced_fare_programs" | _]}) do
    old_site_redirect(conn, fare_url(conn, :show, :reduced))
  end
  def fares_and_passes(conn, %{"path" => ["mticketing" | _], "id" => id}) when id in ["25903", "25905"] do
    old_site_redirect(conn, how_to_pay_url(conn, :show, :commuter_rail))
  end
  def fares_and_passes(conn, %{"path" => ["mticketing" | _], "id" => "25904"}) do
    old_site_redirect(conn, customer_support_url(conn, :index))
  end
  def fares_and_passes(conn, %{"path" => ["mticketing" | _]}) do
    old_site_redirect(conn, fare_url(conn, :show, :payment_methods))
  end
  def fares_and_passes(conn, _params) do
    old_site_redirect(conn, fare_url(conn, :index))
  end

  def customer_support(conn, _params) do
    old_site_redirect(conn, customer_support_url(conn, :index))
  end

  def archived_files(conn, _params) do
    "archive/archived_feeds.txt"
    |> s3_file_url()
    |> perform_uploaded_files_request(conn)
  end

  def uploaded_files(conn, %{"path" => [file_name]}) when file_name in @s3_files do
    file_name |> s3_file_url() |> perform_uploaded_files_request(conn)
  end
  def uploaded_files(conn, %{"path" => path_parts}) do
    path_parts |> old_site_file_url() |> perform_uploaded_files_request(conn)
  end

  defp perform_uploaded_files_request(full_url, conn) do
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
        file_not_found(conn)
    end
  end

  defp file_not_found(conn) do
    conn
    |> put_status(:not_found)
    |> render(Site.ErrorView, "404.html", [])
    |> halt
  end

  defp old_site_file_url(path_parts) do
    host = :site |> Application.get_env(:former_mbta_site) |> Keyword.get(:host)
    "#{host}/uploadedfiles/#{path_parts |> Enum.map(&URI.encode/1) |> Enum.join("/")}"
  end

  defp s3_file_url(file_name) do
    bucket_name = bucket_name(Application.get_env(:site, OldSiteRedirectController)[:gtfs_s3_bucket])
    "https://s3.amazonaws.com/#{bucket_name}/#{URI.encode(file_name)}"
  end

  defp bucket_name({:system, env_var, default}) do
    if value = System.get_env(env_var), do: value, else: default
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
