defmodule Routes.Pdf do
  alias Routes.Route

  @routes_to_pdfs "priv/pdfs.csv"
    |> File.stream!
    |> CSV.decode

  @spec url(Route.t) :: String.t | nil
  for [route_id, pdf_url] <- @routes_to_pdfs do
    def url(%Route{id: unquote(route_id)}), do: unquote(pdf_url)
  end
  def url(%Route{}), do: nil
end
