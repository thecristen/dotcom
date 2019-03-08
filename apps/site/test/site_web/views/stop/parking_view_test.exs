defmodule SiteWeb.Stop.ParkingViewTest do
  @moduledoc false
  use ExUnit.Case, async: true
  import SiteWeb.StopV1View.Parking
  alias Stops.Stop.ParkingLot
  import Phoenix.HTML, only: [safe_to_string: 1]

  @lot %ParkingLot{
    name: "Parking Lot",
    address: "123 Parking Lot Ave.",
    capacity: %ParkingLot.Capacity{
      total: 24,
      accessible: 2,
      type: "Garage"
    },
    payment: %ParkingLot.Payment{
      methods: ["Pay by Phone", "Credit/Debit Card"],
      mobile_app: %ParkingLot.Payment.MobileApp{
        name: "ParkingApp",
        id: "1515",
        url: "www.mobileapp.com"
      },
      daily_rate: "$10",
      monthly_rate: "$444"
    },
    utilization: %ParkingLot.Utilization{
      typical: 10,
      arrive_before: "06:00 AM"
    },
    manager: %ParkingLot.Manager{
      name: "Operator",
      contact: "ParkingLotContact",
      phone: "a phone number",
      url: "manager url"
    },
    note: "Special instructions about parking"
  }

  describe "list_item/2" do
    test "returns empty if item is nil" do
      assert list_item("Parking spaces: ", nil) == ""
    end

    test "returns a list item with title and item" do
      title = "Title: "
      item = "item"
      assert safe_to_string(list_item(title, item)) == "<li><strong>Title: </strong>item</li>"
    end
  end

  describe "utilization/1" do
    test "prints information about arrival time if utilization is greater than 90%" do
      message =
        utilization(%{
          @lot
          | utilization: %ParkingLot.Utilization{typical: 24, arrive_before: "06:00 AM"}
        })

      assert safe_to_string(message) =~ "06:00 AM"
    end

    test "prints a message if utilization does not generally exceed capacity" do
      message = utilization(@lot)
      assert safe_to_string(message) =~ "generally available"
    end

    test "returns nil if any of the required fields are missing" do
      assert utilization(%{@lot | utilization: nil}) == nil
    end
  end

  describe "capacity/1" do
    test "prints capacity data in an unordered list" do
      out = safe_to_string(capacity(@lot.capacity))
      assert out =~ "Total parking spaces:"
      assert out =~ "24"
      assert out =~ "Accessible spaces:"
      assert out =~ "2"
      assert out =~ "Type:"
      assert out =~ "Garage"
    end
  end

  describe "payment/1" do
    test "prints out payment info in an unordered list" do
      out = safe_to_string(payment(@lot.payment))
      assert out =~ "Payment methods:"
      assert out =~ "Pay by Phone, Credit/Debit Card"
      assert out =~ "Mobile app:"
      assert out =~ "www.mobileapp.com"
      assert out =~ "ParkingApp"
      assert out =~ "#1515"
      assert out =~ "Daily fee:"
      assert out =~ "$10"
      assert out =~ "Monthly pass:"
      assert out =~ "$444"
    end

    test "doesn't print id if no mobile app id" do
      out =
        safe_to_string(
          payment(%{
            @lot.payment
            | mobile_app: %ParkingLot.Payment.MobileApp{
                name: "AppName",
                id: nil,
                url: "www.app.com"
              }
          })
        )

      refute out =~ "#"
    end

    test "prints name without url if no url" do
      out =
        safe_to_string(
          payment(%{
            @lot.payment
            | mobile_app: %ParkingLot.Payment.MobileApp{name: "AppName", id: "3", url: nil}
          })
        )

      assert out =~ "AppName"
      assert out =~ "#3"
    end
  end

  describe "manager/1" do
    test "prints out management info" do
      out = safe_to_string(manager(@lot.manager))
      assert out =~ "Managed by:"
      assert out =~ "Operator"
      assert out =~ "Contact:"
      assert out =~ "manager url"
      assert out =~ "ParkingLotContact"
      assert out =~ "Contact phone:"
      assert out =~ "a phone number"
    end
  end

  test "prints name without url if no url" do
    out = safe_to_string(manager(%{@lot.manager | url: nil}))
    assert out =~ "ParkingLotContact"
    refute out =~ "manager url"
  end

  test "doesn't print phone if no phone" do
    out = safe_to_string(manager(%{@lot.manager | phone: nil}))
    refute out =~ "Contact phone:"
  end

  describe "note/1" do
    test "prints out parking note if there is one" do
      out = safe_to_string(note(@lot.note))
      assert out =~ "Special instructions"
    end

    test "doesn't print out a note if there isn't one" do
      out = note(%ParkingLot{note: nil}.note)
      assert out == nil
    end
  end
end
