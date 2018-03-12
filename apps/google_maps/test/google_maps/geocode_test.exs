defmodule GoogleMaps.GeocodeTest do
  use ExUnit.Case
  import GoogleMaps.Geocode
  alias GoogleMaps.Geocode.Address

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

      address = "zero results"

      Bypass.expect bypass, fn conn ->
        assert "/maps/api/geocode/json" == conn.request_path
        conn = Plug.Conn.fetch_query_params(conn)
        assert conn.params["address"] == address

        Plug.Conn.resp(conn, 200, ~s({"status": "ZERO_RESULTS", "error_message": "Message"}))
      end

      actual = geocode(address)
      assert {:error, :zero_results} = actual
    end

    test "returns :ok for one valid responses" do
      bypass = Bypass.open
      set_domain("http://localhost:#{bypass.port}")

      address = "one response"

      Bypass.expect bypass, fn conn ->
        assert "/maps/api/geocode/json" == conn.request_path
        conn = Plug.Conn.fetch_query_params(conn)
        assert conn.params["address"] == address

        Plug.Conn.resp(conn, 200, ~s({"status": "OK", "results": [#{@result1}]}))
      end

      actual = geocode(address)
      assert {:ok, [result]} = actual
      assert %GoogleMaps.Geocode.Address{} = result
    end

    test "returns :ok for multiple matches" do
      bypass = Bypass.open
      set_domain("http://localhost:#{bypass.port}")

      address = "multiple matches"

      Bypass.expect bypass, fn conn ->
        assert "/maps/api/geocode/json" == conn.request_path
        conn = Plug.Conn.fetch_query_params(conn)
        assert conn.params["address"] == address

        Plug.Conn.resp(conn, 200, ~s({"status": "OK", "results": [#{@result1}, #{@result2}]}))
      end

      actual = geocode(address)
      assert {:ok, [result1, result2]} = actual
      assert %GoogleMaps.Geocode.Address{} = result1
      assert %GoogleMaps.Geocode.Address{} = result2
    end

    test "returns :error if the domain doesn't load" do
      set_domain("http://localhost:0")

      address = "bad domain"

      log = ExUnit.CaptureLog.capture_log(fn ->
        actual = geocode(address)
        assert {:error, :internal_error} = actual
      end)
      assert log =~ "HTTP error"
    end

    test "returns :error with error and message from google" do
      bypass = Bypass.open
      set_domain("http://localhost:#{bypass.port}")

      address = "google error"

      Bypass.expect bypass, fn conn ->
        assert "/maps/api/geocode/json" == conn.request_path
        conn = Plug.Conn.fetch_query_params(conn)
        assert conn.params["address"] == address

        Plug.Conn.resp(conn, 200, ~s({"status": "INVALID_REQUEST", "error_message": "Message"}))
      end

      log = ExUnit.CaptureLog.capture_log(fn ->
        actual = geocode(address)
        assert {:error, :internal_error} == actual
      end)
      assert log =~ "API error"
    end

    test "returns :error if the status != 200" do
      bypass = Bypass.open
      set_domain("http://localhost:#{bypass.port}")

      address = "not 200 response"

      Bypass.expect bypass, fn conn ->
        Plug.Conn.resp(conn, 500, "")
      end

      log = ExUnit.CaptureLog.capture_log(fn ->
        actual = geocode(address)
        assert {:error, :internal_error} = actual
      end)
      assert log =~ "Unexpected HTTP code"
    end

    test "returns :error if the JSON is invalid" do
      bypass = Bypass.open
      set_domain("http://localhost:#{bypass.port}")

      address = "invalid json"

      Bypass.expect bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "{")
      end

      log = ExUnit.CaptureLog.capture_log(fn ->
        actual = geocode(address)
        assert {:error, :internal_error} = actual
      end)
      assert log =~ "Error parsing to JSON"
    end

    test "uses cache" do
      bypass = Bypass.open
      set_domain("http://localhost:#{bypass.port}")

      address = "cached"

      Bypass.expect_once bypass, fn conn ->
        assert "/maps/api/geocode/json" == conn.request_path
        conn = Plug.Conn.fetch_query_params(conn)
        assert conn.params["address"] == address

        Plug.Conn.resp(conn, 200, ~s({"status": "OK", "results": [#{@result1}]}))
      end

      cache_miss = geocode(address)
      assert {:ok, [cache_miss_result]} = cache_miss
      assert %GoogleMaps.Geocode.Address{} = cache_miss_result

      cache_hit = geocode(address)
      assert {:ok, [cache_hit_result]} = cache_hit
      assert %GoogleMaps.Geocode.Address{} = cache_hit_result
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
    test "implements the Util.Position protocol" do
      Protocol.assert_impl!(Util.Position, Address)
      address = %Address{}
      assert Util.Position.latitude(address) == address.latitude
      assert Util.Position.longitude(address) == address.longitude
    end
  end
end
