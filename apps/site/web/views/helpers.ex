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

  def google_api_key do
    env(:google_api_key)
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
  def direction(direction_id, route_id)
  def direction(0, "Red"), do: "Southbound"
  def direction(1, "Red"), do: "Northbound"
  def direction(0, "Orange"), do: "Southbound"
  def direction(1, "Orange"), do: "Northbound"
  def direction(0, "Blue"), do: "Westbound"
  def direction(1, "Blue"), do: "Eastbound"
  def direction(0, "Green" <> _), do: "Westbound"
  def direction(1, "Green" <> _), do: "Eastbound"
  def direction(0, _), do: "Outbound"
  def direction(1, _), do: "Inbound"
  def direction(_, _), do: "Unknown"

  @doc "HTML for an icon representing the mode of %Routes.Route."
  @spec mode_icon(Routes.Route.t | Routes.Route.route_type | :access) :: Phoenix.HTML.Safe.t
  def mode_icon(%Routes.Route{type: 0, id: "Mattapan"}), do: do_mode_icon("mattapan", "subway", :subway)
  def mode_icon(%Routes.Route{type: 0}), do: do_mode_icon("green", "subway", :subway)
  def mode_icon(%Routes.Route{type: 1, id: id}) do
    do_mode_icon(String.downcase(id), "subway", :subway)
  end
  def mode_icon(%Routes.Route{type: 1}), do: do_mode_icon("subway", "subway", :subway)
  def mode_icon(%Routes.Route{type: 2}), do: do_mode_icon("commuter", "commuter", :commuter)
  def mode_icon(%Routes.Route{type: 3}), do: do_mode_icon("bus", "bus", :bus)
  def mode_icon(%Routes.Route{type: 4}), do: do_mode_icon("ferry", "ferry", :ferry)
  def mode_icon(:the_ride), do: do_mode_icon("the-ride", "the-ride", :the_ride)
  def mode_icon(atom) when is_atom(atom) do
    string = Atom.to_string(atom)
    do_mode_icon(string, string, atom)
  end

  defp do_mode_icon(name, svg_name, mode_type) do
    content_tag :span, title: mode_name(mode_type), class: "route-icon route-icon-#{name}" do
      svg("#{svg_name}.svg")
    end
  end

  @doc "Textual version of a mode ID or type"
  @spec mode_name(0..4 | Routes.Route.route_type | :access) :: String.t
  def mode_name(type) when type in [0, 1, :subway], do: "Subway"
  def mode_name(type) when type in [2, :commuter], do: "Commuter Rail"
  def mode_name(type) when type in [3, :bus], do: "Bus"
  def mode_name(type) when type in [4, :ferry], do: "Ferry"
  def mode_name(:access), do: "Access"
  def mode_name(:the_ride), do: "The Ride"

  @spec subway_name(String.t) :: String.t
  @doc "Textual version of subway line"
  def subway_name("Red"<>_line), do: "Red Line"
  def subway_name("Green"<>_line), do: "Green Line"
  def subway_name("Blue"<>_line), do: "Blue Line"
  def subway_name("Orange"<>_line), do: "Orange Line"
  def subway_name("Mattapan"<>_line), do: "Red Line"

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

  def update_query(%{params: params}, query) do
    params = params || %{}
    query_map = query
    |> Enum.map(fn {key, value} -> {Atom.to_string(key), value} end)
    |> Enum.into(%{})

    params
    |> Map.merge(query_map)
    |> Enum.reject(&empty_value?/1)
    |> Enum.into(%{})
  end

  def update_url(%Plug.Conn{} = conn, query) do
    conn
    |> update_query(query)
    |> do_update_url(conn)
  end

  defp do_update_url(updated, conn) when updated == %{} do
    conn.request_path
  end
  defp do_update_url(updated, conn) do
    "#{conn.request_path}?#{URI.encode_query(updated)}"
  end

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
    |> Dict.put(:conn, conn)
  end

  defp empty_value?({_, nil}), do: true
  defp empty_value?({_, _}), do: false

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
end
