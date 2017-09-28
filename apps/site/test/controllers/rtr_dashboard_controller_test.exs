defmodule RtrDashboardControllerTest do
  use Site.ConnCase
  import Mock

  describe "index/0" do
    test "renders", %{conn: conn} do
      conn = get(conn, rtr_dashboard_path(conn, :index))
      assert html_response(conn, 200) =~ "RTR Accuracy Data:"
    end
  end

  describe "RtrDashboardData" do
    test "makes a request to the right api" do
      current_date = Timex.shift(Util.service_date, days: -1)
      base_url = Application.get_env(:site, :rtr_accuracy_api_url)
      query_string = "?api_key=rMKswlBRmEGhsziJHxx6Pg&format=json&from_service_date=#{current_date}&route=&to_service_date=#{current_date}"
      with_mock HTTPoison, [get: fn(_params) -> {:ok, []} end] do
        Site.RtrDashboardData.get(%{})
        assert called HTTPoison.get(base_url <> query_string)
      end
    end
  end
end
