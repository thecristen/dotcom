defmodule Alerts do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(ConCache, [[ttl: :timer.seconds(86_400),
                         ttl_check: :timer.seconds(60)], [name: :alerts_parent_ids]])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Alerts.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
