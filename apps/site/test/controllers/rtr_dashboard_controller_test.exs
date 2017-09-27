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
      url = "http://23.21.118.89/developer/api/v2-test/dailypredictionmetrics?api_key=rMKswlBRmEGhsziJHxx6Pg&format=json&from_service_date=2017-09-26&route=&to_service_date=2017-09-26"
      with_mock HTTPoison, [get: fn(_params) -> {:ok, []} end] do
        Site.RtrDashboardData.get(%{})
        assert called HTTPoison.get(url)
      end
    end
  end
end
