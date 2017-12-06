defmodule Util do
  require Logger
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
  Converts an {:error, _} tuple to a default value.

  # Examples

    iex> Util.error_default(:value, :default)
    :value
    iex> Util.error_default({:error, :tuple}, :default)
    :default
  """
  @spec error_default(value | {:error, any}, value) :: value
  when value: any
  def error_default(error_or_default, default)
  def error_default({:error, _}, default) do
    default
  end
  def error_default(value, _default) do
    value
  end

  @doc """

  The current service date.  The service date lasts from 3am to 2:59am, so
  times after midnight belong to the service of the previous date.

  """
  def service_date(current_time \\ Util.now()) do
    %{year: year, month: month, day: day} = Timex.shift(current_time, hours: -3)
    {:ok, date} = Date.new(year, month, day)
    date
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

  @doc """
  Calls all the functions asynchronously, and returns a list of results.
  If a function times out, its result will be the provided default.
  """
  @spec async_with_timeout([(() -> any)], any, non_neg_integer) :: [any]
  def async_with_timeout(functions, default, timeout \\ 5000) do
    tasks = Enum.map(functions, &Task.async/1)
    for task <- tasks do
      yield_or_default(task, timeout, default)
    end
  end

  @doc """
  Yields the value from a task, or returns a default value.
  """
  @spec yield_or_default(Task.t, non_neg_integer, any) :: any
  def yield_or_default(task, timeout, default) do
    case Task.yield(task, timeout) || Task.shutdown(task, :brutal_kill) do
     {:ok, result} ->
        result
      _ ->
        _ = Logger.warn(fn -> "async task timed out. Returning: #{inspect(default)}" end)
        default
    end
  end
end
