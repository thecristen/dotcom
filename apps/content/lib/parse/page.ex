defmodule Content.Parse.Page do
  def parse(body) when is_binary(body) do
    with {:ok, json} <- Poison.Parser.parse(body) do
      parse_json(json)
    end
  end

  defp parse_json(%{
        "title" => [%{"value" => title}],
        "body" => [%{"value" => body}],
        "changed" => [%{"value" => timestamp_str}]
                  }) do
    with {timestamp, ""} <- Integer.parse(timestamp_str),
         updated_at <- Timex.from_unix(timestamp) do
      {:ok, %Content.Page{
          title: title,
          body: body,
          updated_at: updated_at}}
    else
      _ ->
        {:error, "invalid timestamp: #{timestamp_str}"}
    end
  end
  defp parse_json(_) do
    {:error, "missing fields in JSON"}
  end
end
