defmodule Alerts.Repo do
  def all do
    V3Api.Alerts.all.data
    |> Enum.map(&Alerts.Parser.parse/1)
  end
end
