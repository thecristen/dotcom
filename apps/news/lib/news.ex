defmodule News do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    url = Application.get_env(:news, :post_url)

    children = if url != nil do
      [
        worker(News.Repo.Ets, []),
        worker(News.Fetch, [url]),
      ]
    else
      []
    end

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_all, name: News.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
