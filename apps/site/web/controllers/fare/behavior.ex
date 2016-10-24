defmodule Site.FareController.Behaviour do
  @moduledoc "Behaviour for fare pages."

  @doc "The name of the template to render"
  @callback template() :: String.t

  @doc "Given a Plug.Conn, returns a list of fares for the page"
  @callback fares(Plug.Conn.t) :: [Fares.Fare.t]

  @doc "Given a list of Fares, returns the filters to use/display"
  @callback filters([Fares.Fare.t]) :: [Site.FareController.Filter.t]

  @doc "An optional callback to add additional data to the Plug.Conn"
  @callback before_render(Plug.Conn.t) :: Plug.Conn.t

  use Site.Web, :controller

  alias Site.FareController.Filter

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

    fares = conn
    |> mode_strategy.fares
    |> filter_reduced(conn.assigns.fare_type)

    filters = mode_strategy.filters(fares)
    selected_filter = selected_filter(filters, conn.params["filter"])

    conn
    |> render(
      mode_strategy.template,
      selected_filter: selected_filter,
      filters: filters)
  end

  defp fare_type(%{params: %{"fare_type" => fare_type}}) when fare_type in ["senior_disabled", "student"] do
    String.to_existing_atom(fare_type)
  end
  defp fare_type(_) do
    nil
  end

  def filter_reduced(fares, reduced) when is_atom(reduced) or is_nil(reduced) do
    fares
    |> Enum.filter(&match?(%{reduced: ^reduced}, &1))
  end

  def selected_filter(filters, filter_id)
  def selected_filter([], _) do
    nil
  end
  def selected_filter([filter | _], nil) do
    filter
  end
  def selected_filter(filters, filter_id) do
    case Enum.find(filters, &match?(%Filter{id: ^filter_id}, &1)) do
      nil -> selected_filter(filters, nil)
      found -> found
    end
  end
end
