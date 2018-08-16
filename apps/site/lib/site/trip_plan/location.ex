defmodule Site.TripPlan.Location do
  alias Site.TripPlan.Query
  alias TripPlan.NamedPosition

  @spec validate(Query.t, map) :: Query.t
  def validate(%Query{} = query, %{
    "to_latitude" => _,
    "to_longitude" => _,
    "to" => _
  } = params) do
    validate_lat_lng(:to, params, query)
  end

  def validate(%Query{} = query, %{
    "from_latitude" => _,
    "from_longitude" => _,
    "from" => _
  } = params) do
    validate_lat_lng(:from, params, query)
  end

  def validate(%Query{} = query, %{"to" => _} = params) do
    validate_by_name(:to, query, params)
  end

  def validate(%Query{} = query, %{"from" => _} = params) do
    validate_by_name(:from, query, params)
  end

  def validate(%Query{} = query, %{}) do
    query
  end

  @spec validate_lat_lng(:to | :from, map, Query.t) :: Query.t
  defp validate_lat_lng(field_atom, params, %Query{} = query) do
    field = Atom.to_string(field_atom)
    {lat_bin, params} = Map.pop(params, field <> "_latitude")
    {lng_bin, params} = Map.pop(params, field <> "_longitude")

    with {lat, ""} <- Float.parse(lat_bin),
         {lng, ""} <- Float.parse(lng_bin) do

      {name, params} = Map.pop(params, field)

      position = %NamedPosition{
        latitude: lat,
        longitude: lng,
        name: name
      }

      query
      |> Map.put(field_atom, position)
      |> validate(params)
    else
      :error ->
        validate(query, params)
    end
  end

  @spec validate_by_name(:to | :from, Query.t, map) :: Query.t
  defp validate_by_name(field, %Query{} = query, params) do
    {val, params} = Map.pop(params, Atom.to_string(field))
    case val do
      "" ->
        do_validate_by_name({:error, :required}, field, query, params)

      <<location::binary>> ->
        # lat/lng was missing or invalid; attempt geolocation based on name
        location
        |> TripPlan.geocode()
        |> do_validate_by_name(field, query, params)
    end
  end

  @spec do_validate_by_name(TripPlan.Geocode.t, :to | :from, Query.t, map) :: Query.t
  defp do_validate_by_name(result, field, query, params) do
    value = case result do
      {:ok, %NamedPosition{} = position} -> position
      {:error, error} -> {:error, error}
    end

    query
    |> Map.put(field, value)
    |> validate(params)
  end
end
