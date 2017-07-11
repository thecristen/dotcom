defmodule Site.CustomerSupportController do
  use Site.Web, :controller
  import Site.Validation, only: [validate: 2]

  plug Turbolinks.Plug.NoCache

  def index(conn, _params) do
    render_form conn, [], %{}
  end

  def thanks(conn, _params) do
    render conn, "index.html", breadcrumbs: ["Customer Support"], show_form: false
  end

  def submit(conn, params) do
    errors = do_validation(params)
    if Enum.empty?(errors) do
      {:ok, pid} = Task.start(__MODULE__, :send_ticket, [params])
      conn = Plug.Conn.put_private(conn, :ticket_task, pid)
      redirect conn, to: customer_support_path(conn, :thanks)
    else
      conn
      |> put_status(400)
      |> render_form(errors, params)
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

  @spec do_validation(map) :: []
  defp do_validation(params) do
    validators = if params["request_response"] == "on" do
      [&validate_comments/1, &validate_name/1, &validate_contacts/1, &validate_privacy/1]
    else
      [&validate_comments/1]
    end

    validate(validators, params)
  end

  @spec validate_comments(map) :: {:ok, map} | {:error, String.t}
  defp validate_comments(%{"comments" => ""}) do
    {:error, "comments"}
  end
  defp validate_comments(_) do
    {:ok, nil}
  end

  @spec validate_name(map) :: {:ok, map} | {:error, String.t}
  defp validate_name(%{"name" => ""}) do
    {:error, "name"}
  end
  defp validate_name(_) do
    {:ok, nil}
  end

  @spec validate_contacts(map) :: {:ok, map} | {:error, String.t}
  defp validate_contacts(%{"phone" => << _, _ :: binary >>}) do
    {:ok, nil}
  end
  defp validate_contacts(%{"email" => email}) do
    case Regex.run(~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/, email) do
      nil ->
        {:error, "contacts"}
      [_] ->
        {:ok, nil}
    end
  end
  defp validate_contacts(_), do: {:error, "contacts"}

  @spec validate_privacy(map) :: {:ok, map} | {:error, String.t}
  defp validate_privacy(%{"privacy" => "on"}), do: {:ok, nil}
  defp validate_privacy(_) do
    {:error, "privacy"}
  end

  def send_ticket(params) do
    photo_info = cond do
      "photos" in Map.keys(params) -> params["photos"]
      true -> nil
    end
    Feedback.Repo.send_ticket(
      %Feedback.Message{
        photos: photo_info,
        email: params["email"],
        phone: params["phone"],
        name: params["name"],
        comments: params["comments"],
        request_response: params["request_response"] == "on"
      }
    )
  end
end
