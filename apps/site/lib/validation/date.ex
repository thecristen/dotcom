defmodule Site.Validation.Date do

  @spec date_string_ok(map) :: {:ok, map} | {:error, String.t}
  def date_string_ok(%{"date_string" => date_string}) do
    {result, date_time} = Timex.parse(date_string, "{YYYY}-{M}-{D}T{h24}:{m}:{s}")
    case result do
      :ok -> is_valid(date_time)
      _ -> {:error, "date_invalid"}
    end
  end
  def date_string_ok(_), do: {:ok, %{}}

  @spec is_valid(NaiveDateTime.t) :: {:ok, map} | {:error, String.t}
  defp is_valid(date_time) do
    if Timex.is_valid?(date_time) do
      {:ok, %{"naive_date" => date_time}}
    else
      {:error, "date_invalid"}
    end
  end

  @spec date_string_is_in_future(map) :: {:ok, map} | {:error, String.t}
  def date_string_is_in_future(%{"naive_date" => naive_date, "system_date_time" => system_date_time}) do
    naive_date = Timex.to_datetime(naive_date, "America/New_York")
    if Timex.after?(naive_date, system_date_time) do
      {:ok, %{}}
    else
      {:error, "date_past"}
    end
  end
  def date_string_is_in_future(_), do: {:ok, %{}}

end
