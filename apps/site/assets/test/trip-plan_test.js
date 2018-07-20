import { assert } from "chai";
import jsdom from "mocha-jsdom";
import { TripPlannerTimeControls } from "../js/trip-planner-time-controls";
import { TripPlannerLocControls } from "../js/trip-planner-location-controls";

describe("trip-plan", () => {
  var $;
  jsdom();

  beforeEach( () => {
    $ = jsdom.rerequire("jquery");
    window.jQuery = jsdom.rerequire("jquery");
  });

  describe("getFriendlyTime", () => {
    it("returns a friendly string given a JavaScript date", () => {
      const date = new Date(2017, 10, 9, 8, 7);

      assert.equal(TripPlannerTimeControls.getFriendlyTime(date), "8:07 AM")
    });

    it("converts times after 13:00 to PM", () => {
      const date = new Date(2017, 10, 9, 18, 19);

      assert.equal(TripPlannerTimeControls.getFriendlyTime(date), "6:19 PM")
    });

    it("interprets 12:00 as 12:00 PM", () => {
      const date = new Date(2017, 10, 9, 12, 7);

      assert.equal(TripPlannerTimeControls.getFriendlyTime(date), "12:07 PM")
    });

    it("interprets 0:00 as 12:00 AM", () => {
      const date = new Date(2017, 10, 9, 0, 7);

      assert.equal(TripPlannerTimeControls.getFriendlyTime(date), "12:07 AM")
    });
  });

  describe("reverseTrip", () => {
    beforeEach( () => {
      $ = jsdom.rerequire("jquery");
      window.jQuery = jsdom.rerequire("jquery");
      window.jQuery("body").append(`
        <input class="location-input" data-autocomplete="true" id="from" name="plan[from]" placeholder="Ex: 10 Park Plaza" type="text" autocomplete="off">
        <input type="hidden" id="from_latitude" name="plan[from_latitude]">
        <input type="hidden" id="from_longitude" name="plan[from_longitude]">
        <input class="location-input" data-autocomplete="true" id="to" name="plan[to]" placeholder="Ex: Boston Children's Museum" type="text" autocomplete="off">
        <div id="trip-plan-reverse-control"></div>
        <input type="hidden" id="to_latitude" name="plan[to_latitude]">
        <input type="hidden" id="to_longitude" name="plan[to_longitude]">
      `);
    });

    it("swaps the contents of to and from and the from/to lat/lng", () => {
      const tripPlannerLocControls = new TripPlannerLocControls();
      const $ = window.jQuery;
      const $from = $("#from");
      const $from_lat = $("#from_latitude");
      const $from_lng = $("#from_longitude");
      $from.val("A");
      $from_lat.val(1);
      $from_lng.val(2);

      const $to = $("#to");
      const $to_lat = $("#to_latitude");
      const $to_lng = $("#to_longitude");
      $to.val("B");
      $to_lat.val(3);
      $to_lng.val(4);

      $("#trip-plan-reverse-control").trigger("click");
      assert.equal($from.val(), "B");
      assert.equal($to.val(), "A");
      assert.equal($to_lat.val(), 1);
      assert.equal($to_lng.val(), 2);
      assert.equal($from_lat.val(), 3);
      assert.equal($from_lng.val(), 4);
    });
  });
});
