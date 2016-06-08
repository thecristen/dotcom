defmodule V3Api.Schedules do
  @moduledoc """

  Responsible for fetching Schedule data from the V3 API.

  """
  import V3Api

  def all(params \\ []) do
    with {:ok, response} <- get("/schedules/", [], params: params),
         %{body: body, status_code: 200} <- response do
      body
      |> JsonApi.parse
    end
  end
end
