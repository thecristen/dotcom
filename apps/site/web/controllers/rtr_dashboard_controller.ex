defmodule Site.RtrDashboardController do
  use Site.Web, :controller
  @rtr_data Application.get_env(:site, :rtr_data)

  def index(conn, params) do
    conn
    |> render("show.html", accuracies: parse_data(params))
  end

  def parse_data(params) do
    data = @rtr_data.get(params)
    Poison.decode!(data.body)
  end
end

defmodule Site.RtrStaticData do
  @response_body Poison.encode!(
    %{"daily_prediction_metrics" =>
      [%{"metric_result" => "0.6559",
         "route_id" => "Mattapan", "service_date" => "2017-07-27",
         "threshold_id" => "prediction_threshold_id_01",
         "threshold_name" => "0 min <= time away <= 5 min",
         "threshold_type" => "prediction"},
       %{"metric_result" => "0.2354", "route_id" => "Mattapan",
         "service_date" => "2017-07-27",
         "threshold_id" => "prediction_threshold_id_02",
         "threshold_name" => "5 min < time away <= 10 min",
         "threshold_type" => "prediction"}]})

  def get(_params) do
    %HTTPoison.Response{body: @response_body,
      headers: [{"Cache-Control", "no-cache"}, {"Pragma", "no-cache"},
                {"Content-Type", "application/json; charset=utf-8"}, {"Expires", "-1"},
                {"Server", "Microsoft-IIS/7.5"}, {"X-AspNet-Version", "4.0.30319"},
                {"X-Powered-By", "ASP.NET"}, {"Date", "Tue, 26 Sep 2017 22:16:21 GMT"},
                {"Content-Length", "426"}],
              request_url: "http://23.21.118.89/developer/api/v2-test/dailypredictionmetrics?api_key=rMKswlBRmEGhsziJHxx6Pg&format=json&route=Mattapan&from_service_date=2017-07-27&to_service_date=2017-07-27",
              status_code: 200}
  end
end

defmodule Site.RtrDashboardData do
  def get(params) do
    url = "#{Site.RtrDashboardData.base_url()}?#{Site.RtrDashboardData.query_string(params)}"
    {:ok, response} = HTTPoison.get(url)

    response
  end

  def base_url do
    Application.get_env(:site, :rtr_accuracy_api_url)
  end

  def query_string(params) do
    to_date = if params["to_service_date"], do: params["to_service_date"], else: Timex.shift(Util.service_date, days: -1)
    from_date = if params["from_service_date"], do: params["from_service_date"], else: Timex.shift(Util.service_date, days: -1)
    URI.encode_query(
      %{"api_key" => "rMKswlBRmEGhsziJHxx6Pg",
        "format" => "json",
        "route" => params["route"],
        "from_service_date" => from_date,
        "to_service_date" => to_date
      })
  end
end
