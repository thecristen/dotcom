defmodule TripPlan do
  @moduledoc """
  Plan transit trips from one place to another.
  """
  alias Stops.Position

  # Default options for the plans
  @default_opts [
    max_walk_distance: 805, # ~0.5 miles
    personal_mode: :walk
  ]

  @doc """
  Tries to describe how to get between two places.
  """
  @spec plan(Position.t, Position.t, TripPlan.Api.plan_opts) :: TripPlan.Api.t
  def plan(from, to, opts) do
    module = Application.fetch_env!(:trip_plan, Api)[:module]
    apply(module, :plan, [from, to, Keyword.merge(@default_opts, opts)])
  end

  @doc """
  Finds the latitude/longitude for a given address.
  """
  @spec geocode(String.t) :: TripPlan.Geocode.t
  def geocode(address)
  def geocode("") do
    {:error, :required}
  end
  def geocode(address) when is_binary(address) do
    module = Application.fetch_env!(:trip_plan, Geocode)[:module]
    apply(module, :geocode, [address])
  end
end
