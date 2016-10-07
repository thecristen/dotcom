defmodule Site.FareView do
  use Site.Web, :view

  def fare_description(fare) do
    "#{fare_zone_name(fare)} #{fare_pass_duration(fare)}"
  end

  defp fare_zone_name(fare) do
    zone_name = fare.name
                |> Atom.to_string
                |> String.capitalize
                |> String.split("_")
                |> Enum.join(" ")
  end

  defp fare_pass_duration(fare) do
    durations = %{
      single_trip: "One Way",
      month: "Monthly Pass"
    }
    durations[fare.duration]
  end
end
