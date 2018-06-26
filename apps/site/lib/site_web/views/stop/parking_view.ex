defmodule SiteWeb.StopView.Parking do
  alias Stops.Stop.ParkingLot
  import Phoenix.HTML.Tag
  import Phoenix.HTML.Link
  import SiteWeb.ViewHelpers

  @spec parking_lot(ParkingLot.t) :: Phoenix.HTML.Safe.t
  def parking_lot(lot) do
    SiteWeb.StopView.render("_parking_lot.html", %{lot: lot})
  end

  # 4 items are needed to make a summary for utilization:
  # name, capacity, weekday-arrive-before, weekday-typical-utilization
  @spec utilization(ParkingLot.t | any) :: Phoenix.HTML.Safe.t | nil
  def utilization(%ParkingLot{name: name,
                              capacity: %ParkingLot.Capacity{total: total},
                              utilization: %ParkingLot.Utilization{typical: typical, arrive_before: arrive_before}})
                              when typical != nil do
    message = "Parking spots at " <> name <> " fill up quickly."
    content_tag :p do
      if typical / total > 0.9 do
        if arrive_before == nil do
          message
        else
          message <> " We recommend arriving before " <> arrive_before  <> "."
        end
      else
        "Parking at " <> name <> " is generally available throughout the weekday."
      end
    end
  end
  def utilization(_), do: nil

  @spec capacity(ParkingLot.Capacity.t) :: Phoenix.HTML.Safe.t
  def capacity(%ParkingLot.Capacity{total: total, accessible: accessible, type: type}) do
    content_tag :ul, class: "list-unstyled" do
      [
        list_item("Total parking spaces: ", to_string(total)),
        list_item("Accessible spaces: ", to_string(accessible)),
        list_item("Type: ", type)
      ]
    end
  end
  def capacity(nil), do: content_tag :em, "No MBTA parking. Street or private parking may exist."

  @spec payment(ParkingLot.Payment.t | nil) :: Phoenix.HTML.Safe.t
  def payment(%ParkingLot.Payment{methods: methods, mobile_app: app, daily_rate: daily, monthly_rate: monthly}) do
    content_tag :ul, class: "list-unstyled" do
      [
        list_item("Payment methods: ", do_payment_methods(methods)),
        list_item("Mobile app: ", mobile_app(app)),
        list_item("Daily fee: ", daily),
        list_item("Monthly pass: ", monthly)
      ]
    end
  end
  def payment(nil), do: content_tag :em, "No payment information available."

  @spec do_payment_methods([String.t] | nil) :: [String.t] | nil
  defp do_payment_methods(nil), do: nil
  defp do_payment_methods(methods), do: Enum.intersperse(methods, ", ")

  @spec mobile_app(ParkingLot.Payment.MobileApp.t | nil) :: Phoenix.HTML.Safe.t | nil
  defp mobile_app(%ParkingLot.Payment.MobileApp{name: name, id: id, url: url}) do
    [
      mobile_app_link(url, HtmlSanitizeEx.strip_tags(name)),
      mobile_app_id(id)
    ]
  end
  defp mobile_app(nil), do: nil

  @spec mobile_app_link(String.t | nil, String.t) :: Phoenix.HTML.Safe.t | nil
  defp mobile_app_link(nil, name), do: name
  defp mobile_app_link(url, name) do
    link to: external_link(url), do: name
  end

  @spec mobile_app_id(String.t | nil) :: String.t | nil
  defp mobile_app_id(nil), do: ""
  defp mobile_app_id(id), do: " #" <> to_string(id)

  @spec manager(ParkingLot.Manager.t | nil) :: Phoenix.HTML.Safe.t
  def manager(%ParkingLot.Manager{name: name, url: url, contact: contact, phone: phone}) do
    content_tag :ul, class: "list-unstyled" do
      [
        list_item("Managed by: ", name),
        list_item("Contact: ", manager_contact(url, contact)),
        list_item("Contact phone: ", manager_phone(phone)),
      ]
    end
  end
  def manager(nil), do: content_tag :em, "No contact information available."

  @spec manager_contact(String.t | nil, String.t) :: Phoenix.HTML.Safe.t
  defp manager_contact(nil, contact), do: contact
  defp manager_contact(url, contact) do
    link to: external_link(url), do: contact
  end

  @spec manager_phone(String.t | nil) :: Phoenix.HTML.Safe.t | nil
  defp manager_phone(nil), do: nil
  defp manager_phone(phone), do: tel_link phone

  @spec list_item(String.t, any) :: Phoenix.HTML.Safe.t
  def list_item(_title, nil), do: ""
  def list_item(title, item) do
    content_tag :li, [
      content_tag(:strong, title),
      item
    ]
  end
end
