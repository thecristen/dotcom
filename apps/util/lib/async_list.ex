defmodule Util.AsyncList do
  def run(task_defs) do
    task_defs
    |> Enum.map(&apply_task/1)
    |> Task.yield_many
    |> Enum.map(&gather/1)
  end

  defp apply_task({mod, fun, args}) do
    Task.async(mod, fun, args)
  end
  defp apply_task(fun) do
    Task.async(fun)
  end

  defp gather({_, {:ok, value}}) do
    value
  end
end
