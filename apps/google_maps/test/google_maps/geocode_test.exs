defmodule GoogleMaps.GeocodeTest do
  use ExUnit.Case
  import GoogleMaps.Geocode
  alias GoogleMaps.Geocode.Address

  @address "10 Park Plaza 02210"

  @result1 '{
  "address_components" : [{
      "long_name" : "52-2",
      "short_name" : "52-2",
      "types" : [ "street_number" ]
    }],
  "formatted_address" : "52-2 Park Ln, Boston, MA 02210, USA",
  "geometry" : {
    "bounds" : {
      "northeast" : {
        "lat" : 42.3484946,
        "lng" : -71.0389612
      },
      "southwest" : {
        "lat" : 42.3483114,
        "lng" : -71.03938769999999
      }
    },
    "location" : {
      "lat" : 42.3484012,
      "lng" : -71.039176
    }
  }
}'

  @result2 '{
  "address_components" : [{
      "long_name" : "24",
      "short_name" : "24",
      "types" : [ "street_number" ]
    }],
  "formatted_address" : "24 Beacon St, Boston, MA 02133, USA",
  "geometry" : {
    "location" : {
      "lat" : 42.358627,
      "lng" : -71.063767
    }
  }
}'

  describe "geocode/1" do
    test "returns an error for invalid addresses" do
      bypass = Bypass.open
      set_domain("http://localhost:#{bypass.port}")

      Bypass.expect bypass, fn conn ->
        assert "/maps/api/geocode/json" == conn.request_path
        conn = Plug.Conn.fetch_query_params(conn)
        assert conn.params["address"] == "234k-rw0e8r0kew5"

        Plug.Conn.resp(conn, 200, ~s({"status": "ZERO_RESULTS", "error_message": "Message"}))
      end

      actual = geocode("234k-rw0e8r0kew5")
      assert {:error, :zero_results} = actual
    end

    test "returns :ok for one valid responses" do
      bypass = Bypass.open
      set_domain("http://localhost:#{bypass.port}")

      Bypass.expect bypass, fn conn ->
        assert "/maps/api/geocode/json" == conn.request_path
        conn = Plug.Conn.fetch_query_params(conn)
        assert conn.params["address"] == @address

        Plug.Conn.resp(conn, 200, ~s({"status": "OK", "results": [#{@result1}]}))
      end

      actual = geocode(@address)
      assert {:ok, [result]} = actual
      assert %GoogleMaps.Geocode.Address{} = result
    end

    test "returns :ok for multiple matches" do
      bypass = Bypass.open
      set_domain("http://localhost:#{bypass.port}")

      Bypass.expect bypass, fn conn ->
        assert "/maps/api/geocode/json" == conn.request_path
        conn = Plug.Conn.fetch_query_params(conn)
        assert conn.params["address"] == @address

        Plug.Conn.resp(conn, 200, ~s({"status": "OK", "results": [#{@result1}, #{@result2}]}))
      end

      actual = geocode(@address)
      assert {:ok, [result1, result2]} = actual
      assert %GoogleMaps.Geocode.Address{} = result1
      assert %GoogleMaps.Geocode.Address{} = result2
    end

    test "returns :error if the domain doesn't load" do
      set_domain("http://localhost:0")

      actual = geocode(@address)
      assert {:error, :internal_error} = actual
    end

    test "returns :error with error and message from google" do
      bypass = Bypass.open
      set_domain("http://localhost:#{bypass.port}")

      Bypass.expect bypass, fn conn ->
        assert "/maps/api/geocode/json" == conn.request_path
        conn = Plug.Conn.fetch_query_params(conn)
        assert conn.params["address"] == @address

        Plug.Conn.resp(conn, 200, ~s({"status": "INVALID_REQUEST", "error_message": "Message"}))
      end

      actual = geocode(@address)
      assert {:error, :internal_error} == actual
    end

    test "returns :error if the status != 200" do
      bypass = Bypass.open
      set_domain("http://localhost:#{bypass.port}")

      Bypass.expect bypass, fn conn ->
        Plug.Conn.resp(conn, 500, "")
      end

      actual = geocode(@address)
      assert {:error, :internal_error} = actual
    end

    test "returns :error if the JSON is invalid" do
      bypass = Bypass.open
      set_domain("http://localhost:#{bypass.port}")

      Bypass.expect bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "{")
      end

      actual = geocode(@address)
      assert {:error, :internal_error} = actual
    end

    defp set_domain(new_domain) do
      old_domain = Application.get_env(:google_maps, :domain)
      Application.put_env(:google_maps, :domain, new_domain)
      on_exit fn ->
        Application.put_env(:google_maps, :domain, old_domain)
      end
    end
  end

  describe "Address" do
    test "implements the Stops.Position protocol" do
      Protocol.assert_impl!(Stops.Position, Address)
      address = %Address{}
      assert Stops.Position.latitude(address) == address.latitude
      assert Stops.Position.longitude(address) == address.longitude
    end
  end
end
