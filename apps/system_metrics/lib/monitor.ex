defmodule SystemMetrics.Monitor do
  @moduledoc """

  Server for reading metrics each minutes and providing data to exometer

  """
  @meter Application.get_env(:system_metrics, :meter)
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    # schedule work to be performed on start
    schedule_work()
    {:ok, state}
  end

  def handle_info(:work, state) do
    # send cpu stats
    @meter.update_gauge("cpu_load", :cpu_sup.avg1)

    # send memory stats
    memory_data = :memsup.get_system_memory_data
    @meter.update_gauge("memory_used", memory_data[:total_memory] - memory_data[:free_memory])
    @meter.update_gauge("memory_available", memory_data[:free_memory])

    # send erlang stats
    @meter.update_gauge("erlang_active_tasks", :erlang.statistics(:total_active_tasks))
    @meter.update_gauge("erlang_run_queue", :erlang.statistics(:total_run_queue_lengths))
    @meter.update_gauge("erlang_memory", :erlang.memory(:total))

    # reschedule once more
    schedule_work()
    {:noreply, state}
  end

  defp schedule_work do
    Process.send_after(self(), :work, 60 * 1000) # in 1 minute
  end
end
