defmodule V3Api.Alerts do
  @moduledoc """

  Responsible for fetching Alert data from the V3 API.

  """
  import V3Api

  def all do
    with {:ok, response} <- get("/alerts/"),
         %{body: body, status_code: 200} <- response do
      body
      |> JsonApi.parse
    end
  end
end
