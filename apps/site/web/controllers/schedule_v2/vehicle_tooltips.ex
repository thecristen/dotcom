defmodule Site.ScheduleV2Controller.VehicleTooltips do
  @moduledoc """

  Assigns :vehicle_tooltips based on previously requested :route, :vehicle_locations and :vehicle_predictions.

  """
  import Plug.Conn, only: [assign: 3]

  def init([]), do: []

  def call(conn, []) do
    assign(conn, :vehicle_tooltips, VehicleTooltip.build_map(
      conn.assigns[:route].type,
      conn.assigns[:vehicle_locations],
      conn.assigns[:vehicle_predictions]
    ))
  end

end
