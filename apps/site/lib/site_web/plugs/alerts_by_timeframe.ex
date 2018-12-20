defmodule SiteWeb.Plugs.AlertsByTimeframe do
  @moduledoc """
  Filters alerts by timeframe. Used by pages that list alerts
  and have a timeframe filter:

  - /alerts
  - /schedules/ROUTE/alerts
  - /stops/STOP/alerts
  """

  use Plug.Builder

  alias Alerts.Match
  alias Plug.Conn

  @impl Plug
  def call(conn, _) do
    conn
    |> assign_timeframe()
    |> filter_by_timeframe()
  end

  defp assign_timeframe(%{params: %{"alerts_timeframe" => "current"}} = conn) do
    assign(conn, :alerts_timeframe, :current)
  end

  defp assign_timeframe(%{params: %{"alerts_timeframe" => "upcoming"}} = conn) do
    assign(conn, :alerts_timeframe, :upcoming)
  end

  defp assign_timeframe(conn) do
    assign(conn, :alerts_timeframe, nil)
  end

  @spec filter_by_timeframe(Conn.t()) :: Conn.t()
  defp filter_by_timeframe(%{assigns: %{alerts_timeframe: :current}} = conn) do
    alerts = Enum.filter(conn.assigns.alerts, &Match.any_time_match?(&1, conn.assigns.date_time))

    assign(conn, :alerts, alerts)
  end

  defp filter_by_timeframe(%{assigns: %{alerts_timeframe: :upcoming}} = conn) do
    alerts =
      Enum.filter(
        conn.assigns.alerts,
        &(Match.any_time_match?(&1, conn.assigns.date_time) == false)
      )

    assign(conn, :alerts, alerts)
  end

  defp filter_by_timeframe(%{assigns: %{alerts_timeframe: nil}} = conn) do
    conn
  end
end
