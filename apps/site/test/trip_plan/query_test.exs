defmodule Site.TripPlan.QueryTest do
  use ExUnit.Case, async: true

  import Site.TripPlan.Query
  alias Site.TripPlan.Query
  alias TripPlan.NamedPosition

  @date_time Timex.to_datetime(~N[2017-05-30T19:30:00], "America/New_York")
  @date_time_param %{
    "year" => "2017",
    "month" => "5",
    "day" => "30",
    "hour" => "19",
    "minute" => "30"
  }

  describe "from_query/1" do
    test "can plan a basic trip from query params" do
      params = %{"from" => "from address",
                 "to" => "to address"}
      actual = from_query(params)
      assert_received {:geocoded_address, "from address", {:ok, from_position}}
      assert_received {:geocoded_address, "to address", {:ok, to_position}}
      assert_received {:planned_trip, {^from_position, ^to_position, _}, {:ok, itineraries}}
      assert %Query{
        from: {:ok, from_position},
        to: {:ok, to_position},
        itineraries: {:ok, itineraries}
      } == actual
    end

    test "can use lat/lng instead of an address" do
      params = %{"from" => "from address",
                 "to" => "Current Location",
                 "to_latitude" => "42.3428",
                 "to_longitude" => "-71.0857"
                }
      actual = from_query(params)
      to_position = %TripPlan.NamedPosition{latitude: 42.3428, longitude: -71.0857, name: "Current Location"}
      assert_received {:geocoded_address, "from address", {:ok, from_position}}
      assert_received {:planned_trip, {^from_position, ^to_position, _}, {:ok, itineraries}}
      assert %Query{
        from: {:ok, from_position},
        to: {:ok, to_position},
        itineraries: {:ok, itineraries}
      } == actual
    end

    test "ignores lat/lng that are empty strings" do
      params = %{"from" => "from address",
                 "from_latitude" => "",
                 "from_longitude" => "",
                 "to" => "to address"}
      actual = from_query(params)
      assert_received {:geocoded_address, "from address", {:ok, from_position}}
      assert_received {:geocoded_address, "to address", {:ok, to_position}}
      assert_received {:planned_trip, {^from_position, ^to_position, _}, {:ok, itineraries}}
      assert %Query{
        from: {:ok, from_position},
        to: {:ok, to_position},
        itineraries: {:ok, itineraries}
      } == actual
    end

    test "ignores params that are empty strings or missing" do
      params = %{"from" => ""}
      actual = from_query(params)
      assert %Query{
        from: {:error, :required},
        to: {:error, :required},
        itineraries: {:error, :prereq}
      } = actual
    end

    test "can include other params in the plan" do
      params = %{"from" => "from address",
                 "to" => "to address",
                 "time" => "depart",
                 "date_time" => @date_time_param,
                 "include_car?" => "false",
                 "accessible" => "true"}
      from_query(params)
      assert_received {:planned_trip, {_from_position, _to_position, opts}, {:ok, _itineraries}}
      assert opts[:depart_at] == @date_time
      assert opts[:wheelchair_accessible?]
    end

    test "does not plan a trip if we fail to geocode" do
      params = %{"from" => "no results",
                 "to" => "too many results"}
      actual = from_query(params)
      assert_received {:geocoded_address, "no results", from_result}
      assert_received {:geocoded_address, "too many results", to_result}
      refute_received {:planned_trip, _, _}
      assert {:error, :no_results} = from_result
      assert {:error, {:too_many_results, _}} = to_result
      assert %Query{
        from: ^from_result,
        to: ^to_result,
        itineraries: {:error, _}
      } = actual
    end
  end

  describe "fetch_lat_lng/2" do
    test "returns {:ok, lat, lng} when both are parseable floats in params" do
      params = %{"from_latitude" => "42.349159", "from_longitude" => "-71.0655084"}

      assert {:ok, latitude, longitude} = fetch_lat_lng(params, :from)
      assert latitude == 42.349159
      assert longitude == -71.0655084
    end

    test "returns :error if either is an empty string or nil" do
      params = %{"from_latitude" => "42.349159",
                 "from_longitude" => "",
                 "to_longitude" => "-71.0655084"}

      assert fetch_lat_lng(params, :from) == :error
      assert fetch_lat_lng(params, :to) == :error
    end
  end

  describe "itineraries?/1" do
    test "Returns true if query has itineraries" do
      query = %Query{itineraries: {:ok, [%{}]}, from: {:ok, nil}, to: {:ok, nil}}
      assert itineraries?(query)
    end

    test "Returns false if query has no itineraries" do
      query = %Query{itineraries: {:ok, []}, from: nil, to: nil}
      refute itineraries?(query)
    end

    test "Returns false if query recieved an error fetching itineraries" do
      query = %Query{itineraries: {:error, "Could not fetch itineraries"}, from: nil, to: nil}
      refute itineraries?(query)
    end

    test "Returns false if query is nil" do
      refute itineraries?(nil)
    end
  end

  describe "location_name/2" do
    test "Returns from name if one exists" do
      query = %Query{itineraries: {:ok, []}, from: {:ok, %NamedPosition{name: "from name"}}, to: nil}
      assert location_name(query, :from) == "from name"
    end

    test "Returns to name if one exists" do
      query = %Query{itineraries: {:ok, []}, to: {:ok, %NamedPosition{name: "to name"}}, from: nil}
      assert location_name(query, :to) == "to name"
    end

    test "Returns false otherwise" do
      query = %Query{itineraries: {:ok, []}, from: {:error, "error"}, to: nil}
      refute location_name(query, :from)
      refute location_name(query, :to)
    end
  end
end
