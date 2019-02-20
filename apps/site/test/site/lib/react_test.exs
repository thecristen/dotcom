defmodule Site.ReactTest do
  use ExUnit.Case, async: true

  alias ExUnit.CaptureLog
  alias GoogleMaps.Geocode.Address
  alias Site.{React, TransitNearMe}
  alias Site.React.Worker

  @address %Address{
    latitude: 42.352271,
    longitude: -71.055242,
    formatted: "South Station"
  }
  @date Util.service_date()

  describe "render/2" do
    test "renders a component, even when the component has a lot of data" do
      data =
        @address
        |> TransitNearMe.build(date: @date, now: Util.now())
        |> TransitNearMe.schedules_for_routes()

      assert {:safe, body} =
               React.render("TransitNearMe", %{mapId: "map-id", mapData: %{}, sidebarData: data})

      assert body =~ "m-tnm-sidebar"
    end

    test "fail with unknown component" do
      log =
        CaptureLog.capture_log(fn ->
          assert "" ==
                   React.render("TransitNearMeError", %{
                     mapId: "map-id",
                     mapData: %{},
                     sidebarData: []
                   })
        end)

      assert log =~
               "react_renderer component=TransitNearMeError Unknown component: TransitNearMeError"
    end

    test "render" do
      log =
        CaptureLog.capture_log(fn ->
          assert "" ==
                   React.render("TransitNearMe", %{
                     mapId: "map-id",
                     mapData: %{},
                     sidebarData: "crash"
                   })
        end)

      assert log =~ "react_renderer component=TransitNearMe e.reduce is not a function"
    end
  end

  describe "init/1" do
    test "initialize the process" do
      assert {:ok,
              {%{intensity: 3, period: 5, strategy: :one_for_one},
               [
                 {:react_render,
                  {:poolboy, :start_link,
                   [
                     [
                       name: {:local, :react_render},
                       worker_module: Worker,
                       size: 1,
                       max_overflow: 0
                     ],
                     []
                   ]}, :permanent, 5000, :worker, [:poolboy]}
               ]}} = React.init(pool_size: 1)
    end
  end

  describe "stop/0" do
    test "stops the process" do
      assert :ok = React.stop()
    end
  end

  describe "dev_build/1" do
    test "builds files if path is a string" do
      assert React.dev_build("/path/to/ts", fn cmd, args, opts ->
               send(self(), {:cmd, cmd, args, opts})
               {"", 0}
             end) == :ok

      assert_receive {:cmd, "npx", ["webpack"], cd: "/path/to/ts"}
    end

    test "does not build files if path is nil" do
      assert React.dev_build(nil, fn cmd, args, opts ->
               send(self(), {:cmd, cmd, args, opts})
               {"", 0}
             end) == :ok

      refute_receive {:cmd, _, _, _}
    end
  end
end
