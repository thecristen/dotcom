defmodule Util do
  use Timex

  @doc "joins two strings together, separating them with a space"
  def string_join(s1, s2)
  def string_join("", s2), do: s2
  def string_join(s1, ""), do: s1
  def string_join(s1, s2), do: s1 <> " " <> s2

  @doc "The current datetime in the America/New_York timezone."
  def now do
    Timex.now("America/New_York")
  end

  @doc "Today's date in the America/New_York timezone."
  def today do
    now |> Timex.to_date
  end
end
