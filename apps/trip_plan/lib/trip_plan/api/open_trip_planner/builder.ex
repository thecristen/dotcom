defmodule TripPlan.Api.OpenTripPlanner.Builder do
  alias TripPlan.Api.OpenTripPlanner, as: OTP

  @doc "Convert general planning options into query params for OTP"
  @spec build_params(TripPlan.Api.plan_opts) :: {:ok, %{String.t => String.t}} | {:error, any}
  def build_params(opts) do
    do_build_params(opts, %{})
  end

  defp do_build_params([], acc) do
    {:ok, acc}
  end
  defp do_build_params([{:wheelchair_accessible?, bool} | rest], acc) when is_boolean(bool) do
    acc = if bool do
      put_in acc["wheelchair"], "true"
    else
      acc
    end
    do_build_params(rest, acc)
  end
  defp do_build_params([{:max_walk_distance, meters} | rest], acc) when is_number(meters) do
    acc = put_in acc["maxWalkDistance"], "#{meters}"
    do_build_params(rest, acc)
  end
  defp do_build_params([{:depart_at, %DateTime{} = datetime} | rest], acc) do
    local = Timex.to_datetime(datetime, OTP.config(:timezone))
    date = Timex.format!(local, "{ISOdate}")
    time = Timex.format!(local, "{h12}:{0m}{am}")
    acc = Map.merge(acc, %{
          "date" => date,
          "time" => time,
          "arriveBy" => "false"
                    })
    do_build_params(rest, acc)
  end
  defp do_build_params([{:arrive_by, %DateTime{} = datetime} | rest], acc) do
    local = Timex.to_datetime(datetime, OTP.config(:timezone))
    date = Timex.format!(local, "{ISOdate}")
    time = Timex.format!(local, "{h12}:{0m}{am}")
    acc = Map.merge(acc, %{
          "date" => date,
          "time" => time,
          "arriveBy" => "true"
                    })
    do_build_params(rest, acc)
  end
  defp do_build_params([option | _], _) do
    {:error, {:bad_param, option}}
  end
end
