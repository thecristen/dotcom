defmodule Site.ViewHelpers do
  import Site.Router.Helpers
  import Phoenix.HTML, only: [raw: 1]
  import Phoenix.HTML.Link, only: [link: 2]
  import Phoenix.HTML.Tag, only: [content_tag: 3, tag: 2]
  import Plug.Conn

  # precompile the SVGs, rather than hitting the filesystem every time
  for path <- :site
  |> Application.app_dir
  |> Kernel.<>("/priv/static/**/*.svg")
  |> Path.wildcard do
    name = Path.basename(path)
    contents = path
    |> File.read!
    |> String.split("\n")
    |> Enum.join("")
    |> raw

    def svg(unquote(name)) do
      unquote(contents)
    end
  end
  def svg(unknown) do
    raise ArgumentError, message: "unknown SVG #{unknown}"
  end

  def redirect_path(conn, path) do
    redirect_path(conn, :show, []) <> path
  end

  def google_tag_manager_id do
    case env(:google_tag_manager_id) do
      "" -> nil
      id -> id
    end
  end

  def font_awesome_id do
    env(:font_awesome_id)
  end

  def feedback_form_url do
    env(:feedback_form_url)
  end

  defp env(key) do
    Application.get_env(:site, __MODULE__)[key]
  end

  @doc "HTML for a FontAwesome icon, with optional attributes"
  def fa(name, attributes \\ []) when is_list(attributes) do
    content_tag :i, [], [{:"aria-hidden", "true"},
                         {:class, "fa fa-#{name} " <> Keyword.get(attributes, :class, "")} |
                         Keyword.delete(attributes, :class)]
  end

  @doc "The string description of a direction ID"
  def direction(direction_id, route) do
    route.direction_names[direction_id]
  end

  @spec mode_name(0..4 | Routes.Route.route_type | Routes.Route.subway_lines_type | :access) :: String.t
  @doc "Textual version of a mode ID or type"
  def mode_name(type) when type in [0, 1, :subway], do: "Subway"
  def mode_name(type) when type in [2, :commuter_rail], do: "Commuter Rail"
  def mode_name(type) when type in [3, :bus], do: "Bus"
  def mode_name(type) when type in [4, :ferry], do: "Ferry"
  def mode_name(:access), do: "Access"
  def mode_name(:the_ride), do: "The Ride"
  def mode_name(subway_atom) when subway_atom in [:red_line, :blue_line, :orange_line, :green_line, :mattapan_line] do
    subway_atom
    |> Atom.to_string
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  @spec mode_atom(String.t) :: atom
  def mode_atom(type_string) do
    type_string
    |> String.downcase
    |> String.replace(" ", "_")
    |> String.to_existing_atom
  end

  @spec hyphenated_mode_string(atom) :: String.t
  @doc "Returns hyphenated mode string"
  def hyphenated_mode_string(mode) do
    mode
    |> Atom.to_string
    |> String.replace("_", "-")
  end

  @spec subway_name(String.t) :: String.t
  @doc "Textual version of subway line"
  def subway_name("Mattapan"<>_line), do: "Red Line"
  def subway_name("Green"<>_line), do: "Green Line"
  def subway_name(color) when color in ["Red Line", "Blue Line", "Orange Line"], do: color

  @doc "Prefix route name with route for bus lines"
  def route_header_text(%{type: 3, name: name}), do: ["Route ", name]
  def route_header_text(%{type: 2, name: name}), do: clean_route_name(name)
  def route_header_text(%{name: name}), do: name

  @doc "Clean up a GTFS route name for better presentation"
  def clean_route_name(name) do
    name
    |> String.replace_suffix(" Line", "")
    |> String.replace_suffix(" Trolley", "")
    |> String.replace("/", "/​") # slash replaced with a slash with a ZERO
                                # WIDTH SPACE afer
  end

  def route_spacing_class(0), do: "col-xs-6 col-md-3 col-lg-2"
  def route_spacing_class(1), do: "col-xs-6 col-md-3 col-lg-2"
  def route_spacing_class(2), do: "col-xs-12 col-sm-6 col-md-4 col-xxl-3"
  def route_spacing_class(3), do: "col-xs-4 col-sm-3 col-md-2"
  def route_spacing_class(4), do: "col-xs-12 col-sm-6 col-md-4 col-xxl-3"

  def user_agent(conn) do
    case get_req_header(conn, "user-agent") do
      [] -> ""
      [agent | _] -> agent
    end
  end

  def tel_link(number) do
    content_tag :a, number, href: "tel:#{number}"
  end

  def sms_link(number) do
    content_tag :a, number, href: "sms:#{number}"
  end

  def atom_to_string(atom) do
    atom
    |> Atom.to_string
    |> String.split("_")
    |> Enum.map(&(String.capitalize(&1)))
    |> Enum.join(" ")
  end

  @spec format_schedule_time(DateTime.t) :: String.t
  def format_schedule_time(time), do: Timex.format!(time, "{h12}:{m}{AM}")

  def hidden_query_params(conn, opts \\ []) do
    exclude = Keyword.get(opts, :exclude, [])
    include = Keyword.get(opts, :include, %{})
    conn.query_params
    |> Map.merge(include)
    |> Enum.reject(fn {key, _} -> key in exclude end)
    |> Enum.uniq_by(fn {key, _} -> to_string(key) end)
    |> Enum.map(&hidden_tag/1)
  end

  defp hidden_tag({key, value}) do
    tag :input, type: "hidden", name: key, value: value
  end

  @doc """
  Puts the conn into the assigns dictionary so that downstream templates can use it
  """
  def forward_assigns(%{assigns: assigns} = conn) do
    assigns
    |> Map.put(:conn, conn)
  end

  @doc "Link a stop's name to its page."
  @spec stop_link(Stops.Stop.t | String.t) :: Phoenix.HTML.Safe.t
  def stop_link(%Stops.Stop{} = stop) do
    link stop.name, to: stop_path(Site.Endpoint, :show, stop.id)
  end
  def stop_link(stop_id) do
    stop_id
    |> Stops.Repo.get
    |> stop_link
  end

  @spec external_link(String.t) :: String.t
  @doc "Adds protocol if one is needed"
  def external_link(href = <<"http://", _::binary>>), do: href
  def external_link(href = <<"https://", _::binary>>), do: href
  def external_link(href), do: "http://" <> href

  @spec strip_protocol(String.t) :: String.t
  @doc "Returns given url without a protocol"
  def strip_protocol("http://" <> url), do: url
  def strip_protocol("https://" <> url), do: url
  def strip_protocol(url), do: url

  @spec round_distance(float) :: String.t
  def round_distance(distance) when distance < 0.1 do
    distance
    |> Kernel.*(5820)
    |> round()
    |> :erlang.integer_to_binary()
    |> Kernel.<>(" ft")
  end
  def round_distance(distance) do
    distance
    |> :erlang.float_to_binary(decimals: 1)
    |> Kernel.<>(" mi")
  end

  @spec mode_summaries(atom, {atom, String.t} | nil) :: [Fares.Summary.t]
  @doc "Return the fare summaries for the given mode"
  def mode_summaries(:commuter_rail, nil) do
    :commuter_rail
    |> mode_filters(nil)
    |> summaries_for_filters(:commuter_rail)
  end
  def mode_summaries(:commuter_rail, name) do
    :commuter_rail
    |> mode_filters(name)
    |> summaries_for_filters(:bus_subway)
    |> Enum.map(fn(summary) -> %{summary | modes: [:commuter_rail]} end)
  end
  def mode_summaries(:ferry, name) do
    :ferry
    |> mode_filters(name)
    |> summaries_for_filters(:ferry)
  end
  def mode_summaries(:bus, name) do
    :local_bus
    |> mode_filters(name)
    |> summaries_for_filters(:bus_subway)
  end
  def mode_summaries(mode, name) do
    mode
    |> mode_filters(name)
    |> summaries_for_filters(:bus_subway)
  end

  @spec mode_filters(atom, {atom, String.t} | nil) :: [keyword()]
  defp mode_filters(:ferry, _name) do
    [[mode: :ferry, duration: :single_trip, reduced: nil],
     [mode: :ferry, duration: :month, reduced: nil]]
  end
  defp mode_filters(:commuter_rail, nil) do
    [[mode: :commuter_rail, duration: :single_trip, reduced: nil],
     [mode: :commuter_rail, duration: :month, reduced: nil]]
  end
  defp mode_filters(:commuter_rail, name) do
    mode_filters(:commuter_rail, nil)
    |> Enum.map(&(Keyword.put(&1, :name, name)))
  end
  defp mode_filters(:bus_subway, name) do
    [[name: :local_bus, duration: :single_trip, reduced: nil] | mode_filters(:subway, name)]
  end
  defp mode_filters(mode, _name) do
    [[name: mode, duration: :single_trip, reduced: nil],
     [name: mode, duration: :week, reduced: nil],
     [name: mode, duration: :month, reduced: nil]]
  end

  @spec summaries_for_filters([keyword()], atom) :: [Fares.Summary.t]
  defp summaries_for_filters(filters, mode) do
    filters |> Enum.flat_map(&Fares.Repo.all/1) |> Fares.Format.summarize(mode)
  end
end
