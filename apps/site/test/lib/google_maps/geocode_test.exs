defmodule GoogleMaps.GeocodeTest do
  use ExUnit.Case, async: true
  import GoogleMaps.Geocode
  alias GoogleMaps.Geocode.Address

  @address "10 Park Plaza 02210"

  describe "geocode/1" do
    test "returns an error for invalid addresses" do
      actual = geocode("234k-rw0e8r0kew5")
      assert {:error, :zero_results, _msg} = actual
    end

    test "returns :ok for valid responses" do
      actual = geocode(@address)
      assert {:ok, results} = actual
      refute results == []
      for result <- results do
        assert %GoogleMaps.Geocode.Address{} = result
      end
    end

    test "returns :error if the domain doesn't load" do
      set_domain("http://localhost:0")

      actual = geocode(@address)
      assert {:error, _, _} = actual
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
      assert {:error, :invalid_request, "Message"} == actual
    end

    test "returns :error if the status != 200" do
      bypass = Bypass.open
      set_domain("http://localhost:#{bypass.port}")

      Bypass.expect bypass, fn conn ->
        Plug.Conn.resp(conn, 500, "")
      end

      actual = geocode(@address)
      assert {:error, _, _} = actual
    end

    test "returns :error if the JSON is invalid" do
      bypass = Bypass.open
      set_domain("http://localhost:#{bypass.port}")

      Bypass.expect bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "{")
      end

      actual = geocode(@address)
      assert {:error, _, _} = actual
    end

    defp set_domain(new_domain) do
      env = Application.get_env(:site, GoogleMaps)
      Application.put_env(:site, GoogleMaps,
        put_in(env[:domain], new_domain))
      on_exit fn ->
        Application.put_env(:site, GoogleMaps, env)
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
