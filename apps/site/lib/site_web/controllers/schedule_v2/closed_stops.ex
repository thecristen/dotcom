defmodule SiteWeb.ScheduleV2Controller.ClosedStops do

  @spec wollaston_stop(Stops.Stop.t | Stops.RouteStop.t) :: Stops.Stop.t | Stops.RouteStop.t
  def wollaston_stop(stop) do
    reason = "closed for renovation"
    info_link = "/projects/wollaston-station/project-updates/how-the-wollaston-station-improvements-affect-your-trip"

    %{stop | name: "Wollaston",
             id: "place-wstn",
             closed_stop_info: %Stops.Stop.ClosedStopInfo{reason: reason, info_link: info_link}}
  end
end
