defmodule V3Api do
  use HTTPoison.Base

  defp process_url(url) do
    base_url = Application.get_env(:v3_api, :base_url)
    base_url <> url
  end
end
