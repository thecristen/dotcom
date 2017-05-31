defmodule Alerts.SortTest do
  use ExUnit.Case, async: true
  use ExCheck

  alias Alerts.Alert
  import Alerts.Sort

  describe "sort/1" do
    property "sorts the notices by their updated at times (newest to oldest)" do
      date = Timex.today() |> Timex.shift(days: 1) # put them in the future
      for_all times in list(pos_integer()) do
        # create alerts with a bunch of updated_at times
        alerts = for time <- times do
          dt = date |> Timex.shift(seconds: time)
          %Alert{id: inspect(make_ref()),
                 updated_at: dt,
                 active_period: [{nil, nil}]}
        end

        actual = sort(alerts)
        # reverse after ID sort so that the second reverse puts them in the
        # right order
        expected = alerts
        |> Enum.sort_by(&(&1.id))
        |> Enum.reverse()
        |> Enum.sort_by(& &1.updated_at, &Timex.after?/2)

        assert actual == expected
      end
    end
  end
end
