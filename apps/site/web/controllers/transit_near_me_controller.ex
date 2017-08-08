defmodule Site.TransitNearMeController do
  use Site.Web, :controller
  plug Site.Plugs.TransitNearMe

  @doc """
    Handles GET requests both with and without parameters. Calling with an address parameter (String.t) will
    make available to the view:
        @stops_with_routes :: [%{stop: %Stops.Stop{}, routes: [%Route{}]}]

    When javascript is enabled, the form also sends the client width, which we use to determine how many columns to
    group the results into. Creating the groups on the server is admittedly not an ideal solution, but it's the best
    one we've been able to come up with after trying several different options, none of which worked consistently the
    way we wanted them to. Rendering the cards horizontally in rows creates large gaps between rows when there are
    cards of different heights in one row. We can render the cards nicely in columns using the `column-count` CSS
    property, but that makes the cards read top-to-bottom then left-to-right. We found that users expect them to read
    left-to-right and having them read vertically creates confusion. Also, the column property doesn't render the way
    we want it to for small result sets on large displays. For the small number of visitors who have javascript
    disabled, we fall back to relying on `column-count` only, but show only two columns on large displays to prevent
    the rendering issue that we encountered.
  """
  def index(conn, _params) do
    conn
    |> render("index.html", breadcrumbs: [Breadcrumb.build("Transit Near Me")])
  end
end
