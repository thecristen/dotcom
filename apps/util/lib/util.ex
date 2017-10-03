defmodule Util do
  use Timex

  @doc "The current datetime in the America/New_York timezone."
  @spec now() :: DateTime.t
  @spec now((() -> DateTime.t)) :: DateTime.t
  def now(utc_now_fn \\ &Timex.now/0) do
    to_local_time(utc_now_fn.())
  end

  @doc "Today's date in the America/New_York timezone."
  def today do
    now() |> Timex.to_date
  end

  @doc "Converts a DateTime.t into the America/New_York zone, handling ambiguities"
  @spec to_local_time(DateTime.t) :: DateTime.t
  def to_local_time(time) do
    case Timex.Timezone.convert(time, "America/New_York") do
      %Timex.AmbiguousDateTime{before: before} -> before
      time -> time
    end
  end

  @doc """

  The current service date.  The service date lasts from 3am to 2:59am, so
  times after midnight belong to the service of the previous date.

  """
  def service_date(current_time \\ nil) do
    current_time = current_time || Util.now()

    current_time
    |> Timex.shift(hours: -3)
    |> Timex.to_date
  end

  @doc """

  Returns an id property in a struct or nil

  """
  def safe_id(%{id: id}), do: id
  def safe_id(nil), do: nil

  @doc "Interleaves two lists. Appends the remaining elements of the longer list"
  @spec interleave(list, list) :: list
  def interleave([h1|t1], [h2|t2]), do: [h1, h2 | interleave(t1, t2)]
  def interleave([], l), do: l
  def interleave(l, []), do: l
end
