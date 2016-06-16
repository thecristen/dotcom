defmodule V3Api do
  use HTTPoison.Base

  def get_json(url, params \\ []) do
    with {:ok, response} <- get(url, [], params: params),
         %{body: body, status_code: 200} <- response do
      body
      |> JsonApi.parse
    end
  end

  defp process_url(url) do
    base_url = Application.get_env(:v3_api, :base_url)
    base_url <> url
  end
end
