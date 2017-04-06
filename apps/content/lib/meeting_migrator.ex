defmodule Content.MeetingMigrator do
  @spec migrate(String.t) :: {:ok, %HTTPoison.Response{}} | {:error, %HTTPoison.Response{}}
  def migrate(meeting_json) do
    encoded_event_body = build_event(meeting_json)
    meeting_id = meeting_json["meeting_id"]

    if event_id = check_for_existing_event(meeting_id) do
      update_event(event_id, encoded_event_body)
    else
      create_event(encoded_event_body)
    end
  end

  defp build_event(meeting_json) do
    meeting_json
    |> Content.EventPayload.from_meeting()
    |> Poison.encode!
  end

  defp check_for_existing_event(id) do
    response = HTTPoison.get!(events_url(), [], params: ["meeting_id": id])

    response.body
    |> Poison.decode!
    |> List.first
    |> parse_node_id
  end

  defp update_event(id, body) do
    HTTPoison.patch(update_event_url(id), body, headers())
  end

  defp create_event(body) do
    HTTPoison.post(create_event_url(), body, headers())
  end

  defp parse_node_id(%{"nid" => [%{"value" => node_id}]} = _body), do: node_id
  defp parse_node_id(_), do: nil

  defp headers do
    [
      {"Authorization", "Basic #{encoded_auth_credentials()}"},
      {"Content-Type", "application/json"},
    ]
  end

  defp events_url, do: Content.Config.url("events")

  defp update_event_url(id), do: Content.Config.url("node/#{id}")

  defp create_event_url, do: Content.Config.url("entity/node")

  defp encoded_auth_credentials, do: Base.encode64("#{username()}:#{password()}")

  defp username, do: System.get_env("DRUPAL_USERNAME")

  defp password, do: System.get_env("DRUPAL_PASSWORD")
end
