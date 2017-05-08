defmodule Stops.RouteStop do
  @moduledoc """
  A helper module for generating some contextual information about stops on a route. RouteStops contain
  the following information:
  ```
    # RouteStop info for South Station on the Red Line (direction_id: 0)
    %Stops.RouteStop{
      id: "place-sstat",                                  # The id that the stop is typically identified by (i.e. the parent stop's id)
      name: "South Station"                               # Stop's display name
      zone: "1A"                                          # Commuter rail zone (will be nil if stop doesn't have CR routes)
      route: %Routes.Route{id: "Red"...}                  # The full Routes.Route for the parent route
      branch: nil                                         # Name of the branch that this stop is on for this route. will be nil unless the stop is actually on a branch.
      stop_number: 9                                      # The number (0-based) of the stop along the route, relative to the beginning of the line in this direction.
                                                          #     note that for routes with branches, stops that are on branches will be ordered as if no other branches
                                                          #     exist. So, for example, on the Red line (direction_id: 0), the stop number for JFK/Umass is 12, and then
                                                          #     the stop number for both Savin Hill (ashmont) and North Quincy (braintree) is 13, the next stop on both
                                                          #     branches is 14, etc.
      station_info: %Stops.Stop{id: "place-sstat"...}     # Full Stops.Stop struct for the parent stop.
      child_stops: ["70079", "70080"]                     # List of the ids of all the child GTFS stops that this stop represents for this route & direction.

      stop_features: [:commuter_rail, :bus, :accessible]  # List of atoms representing the icons that should be displayed for this stop.
      is_terminus?: false                                 # Whether this is either the first or last stop on the route. Use in conjunction with stop_number to determine
                                                          #     if this is the first or last stop.
    }
  ```

  """

  @type branch_name_t :: String.t
  @type stop_number_t :: integer

  @type t :: %__MODULE__{
    id: Stops.Stop.id_t,
    name: String.t,
    zone: String.t,
    route: Routes.Route.t,
    branch: branch_name_t,
    stop_number: non_neg_integer,
    station_info: Stops.Stop.t,
    child_stops: [Stops.Stop.id_t],
    stop_features: [Routes.Route.route_type | Routes.Route.subway_lines_type | :accessible],
    is_terminus?: boolean
  }

  defstruct [
    :id,
    :name,
    :zone,
    :route,
    :branch,
    :stop_number,
    :station_info,
    child_stops: [],
    stop_features: [],
    is_terminus?: false
  ]
end
