defmodule Site.Fare.FareBehaviour do
  @moduledoc "Behaviour for fare pages."

  @callback mode_name() :: String.t
  @callback template() :: String.t
  @callback fares(Plug.Conn.t) :: [Fares.Fare.t]
  @callback before_render(Plug.Conn.t) :: Plug.Conn.t

  use Site.Web, :controller

  defmacro __using__(_) do
    quote location: :keep do
      @behaviour unquote(__MODULE__)

      use Site.Web, :controller

      def index(conn, _params) do
        unquote(__MODULE__).index(__MODULE__, conn)
      end

      def before_render(conn), do: conn

      defoverridable [before_render: 1]
    end
  end

  def index(mode_strategy, conn)  do
    conn = conn
    |> assign(:fare_type, fare_type(conn))
    |> mode_strategy.before_render

    conn
    |> render(
      mode_strategy.template,
      mode_name: mode_strategy.mode_name,
      fares: mode_strategy.fares(conn))
  end

  defp fare_type(%{params: %{"fare_type" => fare_type}}) when fare_type in ["adult", "senior_disabled", "student"] do
    String.to_existing_atom(fare_type)
  end
  defp fare_type(_) do
    :adult
  end
end
