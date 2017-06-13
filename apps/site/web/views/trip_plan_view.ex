defmodule Site.TripPlanView do
  use Site.Web, :view
  alias Stops.Position

  def optional_position({:ok, _}), do: ""
  def optional_position({:error, {:too_many_results, results}}) do
    content_tag :div do
      [
        "Too many results returned",
        tag(:br),
        content_tag :ul do
          for result <- results do
            content_tag :li, [result.name]
          end
        end
      ]
    end
  end
  def optional_position({:error, error}) do
    "Error: #{inspect error}"
  end

  def itinerary_map_src(itinerary) do
    path_opts = for leg <- itinerary.legs do
      {:path, "enc:#{leg.polyline}"}
    end
    marker_opts = for leg <- itinerary.legs do
      markers = [
        "size:small",
        "#{Position.latitude(leg.from)},#{Position.longitude(leg.from)}",
        "#{Position.latitude(leg.to)},#{Position.longitude(leg.to)}"
      ]
      {:markers, Enum.join(markers, "|")}
    end

    GoogleMaps.static_map_url(600, 600, Enum.concat(path_opts, marker_opts))
  end

  def initial_map_src do
    GoogleMaps.static_map_url(630, 400, [center: "Boston, MA", zoom: 14])
  end
end
