defmodule MapHelpers do
  alias Routes.Route

  @spec map_pdf_url(integer | atom) :: String.t | nil
  def map_pdf_url(mode_number) when mode_number in 0..4 do
    mode_number
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

  @spec map_image_url(integer | atom) :: String.t | nil
  def map_image_url(mode_number) when mode_number in 0..4 do
    mode_number
    |> Route.type_atom
    |> map_image_url
  end
  def map_image_url(:commuter_rail) do
    "/images/commuter-rail-spider.jpg"
  end
  def map_image_url(:ferry) do
    "/images/ferry-spider.jpg"
  end
  def map_image_url(_) do
    "/images/subway-spider.jpg"
  end
end
