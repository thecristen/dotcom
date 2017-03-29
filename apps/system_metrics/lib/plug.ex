defmodule SystemMetrics.Plug do
  @moduledoc """

  Plug for providing request metrics to exometer.

  """
  @behaviour Plug
  @meter Application.get_env(:system_metrics, :meter)
  import Plug.Conn, only: [register_before_send: 2, assign: 3]

  def init(opts), do: opts

  def call(conn, _config) do

    # set the before time at the beginning of request
    conn = assign(conn, :before_time, System.monotonic_time)

    # calculate the end time at end of request lifecycle
    register_before_send conn, fn conn ->
      conn = assign(conn, :after_time, System.monotonic_time)

      # log response time
      diff = round((conn.assigns.after_time - conn.assigns.before_time) / 1_000_000)
      @meter.update_histogram("resp_time", diff)

      # log requests per minute
      @meter.update_counter("req_count", 1, [reset_seconds: 60])

      # log errors per minute
      if conn.status >= 500 do
        @meter.update_counter("errors", 1, [reset_seconds: 60])
      end

      conn
    end
  end
end
