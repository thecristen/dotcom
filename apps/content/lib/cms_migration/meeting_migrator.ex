defmodule Content.CmsMigration.MeetingMigrationError do
  defexception [:message]
end

defmodule Content.CmsMigration.MeetingMigrator do
  alias Content.CmsMigration.EventPayload
  alias Content.CmsMigration.MeetingMigrationError

  @spec migrate(String.t) :: {:ok, atom} | {:error, map} | {:error, String.t}
  def migrate(meeting_json) do
    meeting_id = Map.fetch!(meeting_json, "meeting_id")
    event = build_event(meeting_json)

    case validate_event(event) do
      {:ok, event} -> migrate_event(event, meeting_id)
      {:error, message} -> {:error, message}
    end
  end

  @spec check_for_existing_event!(integer) :: integer | no_return
  def check_for_existing_event!(meeting_id) do
    case Content.Repo.events(meeting_id: meeting_id) do
      [%Content.Event{id: id, meeting_id: ^meeting_id}] -> id
      [] -> nil
      _multiple_records -> raise MeetingMigrationError,
        message: "multiple records were found when querying by meeting_id: #{meeting_id}."
    end
  end

  defp build_event(meeting_json) do
    EventPayload.from_meeting(meeting_json)
  end

  defp migrate_event(event, meeting_id) do
    encoded_event = Poison.encode!(event)

    if event_id = check_for_existing_event!(meeting_id) do
      update_event(event_id, encoded_event)
    else
      create_event(encoded_event)
    end
  end

  defp update_event(id, body) do
    with {:ok, _event} <- Content.Repo.update_event(id, body) do
      {:ok, :updated}
    end
  end

  defp create_event(body) do
    with {:ok, _event} <- Content.Repo.create_event(body) do
      {:ok, :created}
    end
  end

  defp validate_event(%{field_start_time: [%{value: nil}], field_end_time: [%{value: nil}]} = _event) do
    {:error, "A start time must be provided."}
  end
  defp validate_event(%{field_start_time: [%{value: _start_time}], field_end_time: [%{value: nil}]} = event) do
    {:ok, event}
  end
  defp validate_event(%{field_start_time: [%{value: start_time}], field_end_time: [%{value: end_time}]} = event) do
    start_datetime = convert_to_datetime(start_time)
    end_datetime = convert_to_datetime(end_time)

    case NaiveDateTime.compare(start_datetime, end_datetime) do
      :lt -> {:ok, event}
      _ -> {:error, "The start time must be less than the end time."}
    end
  end

  defp convert_to_datetime(time) do
    Timex.parse!(time, "{YYYY}-{0M}-{0D}T{h24}:{m}:{s}")
  end
end
