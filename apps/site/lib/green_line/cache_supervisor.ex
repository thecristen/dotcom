defmodule Site.GreenLine.CacheSupervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, nil, name: :green_line_cache_supervisor)
  end

  def start_child(date) do
    Supervisor.start_child(:green_line_cache_supervisor, [date])
  end

  def init(_) do
    children = [
      worker(Site.GreenLine.DateAgent, [])
    ]
    supervise(children, strategy: :simple_one_for_one)
  end
end
