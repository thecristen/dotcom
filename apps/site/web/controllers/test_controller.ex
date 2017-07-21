defmodule Site.TestController do
  use Site.Web, :controller

  def index(conn, _params) do
    text conn, "{bad: json}"
  end

  def show(conn, _params) do
    V3Api.get_json("/test", [], [base_url: "http://127.0.0.1:4001"]);
    #ThisWillError.api9()
    text conn, "OK"
  end

end
