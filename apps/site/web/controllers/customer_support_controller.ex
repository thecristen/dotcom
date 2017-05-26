defmodule Site.CustomerSupportController do
  use Site.Web, :controller

  plug Turbolinks.Plug.NoCache

  def index(conn, _params) do
    render_form conn, MapSet.new, %{}
  end

  def thanks(conn, _params) do
    render conn, "index.html", breadcrumbs: ["Customer Support"], show_form: false
  end

  def submit(conn, params) do
    errors = validate params
    if MapSet.size(errors) > 0 do
      conn
      |> put_status(400)
      |> render_form(errors, params)
    else
      {:ok, _response} = send_ticket params
      redirect conn, to: customer_support_path(conn, :thanks)
    end
  end

  defp render_form(conn, errors, existing_params) do
    render conn,
      "index.html",
      breadcrumbs: ["Customer Support"],
      errors: errors,
      existing_params: existing_params,
      show_form: true
  end

  defp validate(params) do
    validators = if params["request_response"] == "on" do
      [&validate_comments/1, &validate_name/1, &validate_contacts/1, &validate_privacy/1]
    else
      [&validate_comments/1]
    end

    validators
    |> Enum.reduce(MapSet.new, fn (f, acc) ->
      case f.(params) do
        :ok -> acc
        field -> MapSet.put acc, field
      end
    end)
  end

  defp validate_comments(%{"comments" => ""}) do
    "comments"
  end
  defp validate_comments(_) do
    :ok
  end

  defp validate_name(%{"name" => ""}) do
    "name"
  end
  defp validate_name(_) do
    :ok
  end

  defp validate_contacts(%{"phone" => << _, _ :: binary >>}) do
    :ok
  end
  defp validate_contacts(%{"email" => email}) do
    case Regex.run(~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/, email) do
      nil ->
        "contacts"
      [_] ->
        :ok
    end
  end
  defp validate_contacts(_), do: "contacts"

  defp validate_privacy(%{"privacy" => "on"}), do: :ok
  defp validate_privacy(_) do
    "privacy"
  end

  defp send_ticket(params) do
    photo_info = cond do
      "photo" in Map.keys(params) -> params["photo"]
      "photo-fallback-data" in Map.keys(params) -> {params["photo-fallback-data"], params["photo-fallback-name"]}
      true -> nil
    end
    Feedback.Repo.send_ticket(
      %Feedback.Message{
        photo: photo_info,
        email: params["email"],
        phone: params["phone"],
        name: params["name"],
        comments: params["comments"],
        request_response: params["request_response"] == "on"
      }
    )
  end
end
