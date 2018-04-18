defmodule Util do
  require Logger
  use Timex

  {:ok, endpoint} = Application.get_env(:util, :endpoint)
  {:ok, route_helper_module} = Application.get_env(:util, :router_helper_module)

  @endpoint endpoint
  @route_helper_module route_helper_module
  @local_tz "America/New_York"

  @doc "The current datetime in the America/New_York timezone."
  @spec now() :: DateTime.t
  @spec now((String.t -> DateTime.t)) :: DateTime.t
  def now(utc_now_fn \\ &Timex.now/1) do
    @local_tz
    |> utc_now_fn.()
    |> to_local_time()
    # to_local_time(utc_now_fn.())
  end

  @doc "Today's date in the America/New_York timezone."
  def today do
    now() |> Timex.to_date
  end

  @doc "Converts a DateTime.t into the America/New_York zone, handling ambiguities"
  @spec to_local_time(DateTime.t | NaiveDateTime.t) :: DateTime.t | {:error, any}
  def to_local_time(%DateTime{zone_abbr: zone} = time) when zone in ["EDT", "EST", "-04", "-05"] do
    time
  end
  def to_local_time(%DateTime{zone_abbr: "UTC"} = time) do
    time
    |> Timex.Timezone.convert(@local_tz)
    |> handle_ambiguous_time()
  end
  def to_local_time(%NaiveDateTime{} = time) do
    time
    |> DateTime.from_naive!("Etc/UTC")
    |> to_local_time()
  end

  @spec handle_ambiguous_time(Timex.AmbiguousDateTime.t | DateTime.t | {:error, any}) :: DateTime.t | {:error, any}
  defp handle_ambiguous_time(%Timex.AmbiguousDateTime{before: before}) do
    # ambiguous time only happens between midnight and 3am
    # during November daylight saving transition
    before
  end
  defp handle_ambiguous_time(%DateTime{} = time) do
    time
  end
  defp handle_ambiguous_time({:error, error}) do
    {:error, error}
  end

  def local_tz, do: @local_tz

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
  @spec service_date(DateTime.t | NaiveDateTime.t) :: Date.t
  def service_date(current_time \\ Util.now()) do
    current_time
    |> to_local_time()
    |> do_service_date()
  end

  defp do_service_date(%DateTime{hour: hour} = time) when hour < 3 do
    time
    |> Timex.shift(hours: -3)
    |> DateTime.to_date()
  end
  defp do_service_date(%DateTime{} = time) do
    DateTime.to_date(time)
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
    task
    |> Task.yield(timeout)
    |> task_result_or_default(default, task)
  end

  @doc """
  Takes a map of tasks and calls &Task.yield_many/2 on them, then rebuilds the map with
  either the result of the task, or the default if the task times out or exits early.
  """
  @type task_map :: %{optional(Task.t) => {atom, any}}
  @spec yield_or_default_many(task_map, non_neg_integer) :: map
  def yield_or_default_many(%{} = task_map, timeout \\ 5000) do
    task_map
    |> Map.keys()
    |> Task.yield_many(timeout)
    |> Map.new(&do_yield_or_default_many(&1, task_map))
  end

  @spec do_yield_or_default_many({Task.t, {:ok, any} | {:exit, term} | nil}, task_map) :: {atom, any}
  defp do_yield_or_default_many({%Task{} = task, result}, task_map) do
    {key, default} = Map.get(task_map, task)
    {key, task_result_or_default(result, default, task)}
  end

  @spec task_result_or_default({:ok, any} | {:exit, term} | nil, any, Task.t) :: any
  defp task_result_or_default({:ok, result}, _default, %Task{}) do
    result
  end
  defp task_result_or_default({:exit, _reason}, default, %Task{}) do
    _ = Logger.warn("Async task exited unexpectedly. Returning: #{inspect(default)}")
    default
  end
  defp task_result_or_default(nil, default, %Task{} = task) do
    case Task.shutdown(task, :brutal_kill) do
      {:ok, result} ->
        result
      _ ->
        _ = Logger.warn(fn -> "async task timed out. Returning: #{inspect(default)}" end)
        default
    end
  end

  @doc """
  Makes SiteWeb.Router.Helpers available to other apps.
  #
  # Examples

    iex> Util.site_path(:schedule_path, [:show, "test"])
    "/schedules/test"
  """
  @spec site_path(atom, [any]) :: String.t
  def site_path(helper_fn, opts) when is_list(opts) do
    apply(@route_helper_module, helper_fn, [@endpoint | opts])
  end
end
