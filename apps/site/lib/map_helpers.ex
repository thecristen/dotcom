defmodule MapHelpers do
  alias Routes.Route

  @spec map_pdf_url(integer | atom) :: String.t | nil
  def map_pdf_url(route_number) when route_number in 0..4 do
    route_number
    |> Route.type_atom
    |> map_pdf_url
  end
  def map_pdf_url(:subway) do
    "http://www.mbta.com/uploadedfiles/Documents/Schedules_and_Maps/Rapid%20Transit%20w%20Key%20Bus.pdf"
  end
  def map_pdf_url(:bus) do
    "http://www.mbta.com/uploadedfiles/Documents/Schedules_and_Maps/Rapid%20Transit%20w%20Key%20Bus.pdf"
  end
  def map_pdf_url(:ferry) do
    "https://s3.amazonaws.com/mbta-dotcom/Water_Ferries_2016.pdf"
  end
  def map_pdf_url(:commuter_rail) do
    "http://www.mbta.com/uploadedfiles/Documents/Schedules_and_Maps/Commuter%20Rail%20Map.pdf"
  end
  def map_pdf_url(_) do
    nil
  end
end
