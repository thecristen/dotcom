

##########################################################################################
##########################################################################################
## DATA EXTRACTOR
##########################################################################################
##########################################################################################

defmodule Mix.Tasks.Fares.Locations do
  use Mix.Task
  require Logger
  alias Fares.RetailLocations.{Data, Extractor}

  @moduledoc """
    In order to run this task, get content.csv from the wiki repo (https://github.com/mbta/wiki/blob/master/old-website/content/content.csv).
    If there are updates required for that file, submit a pull request to the wiki repo with the changes in order to keep it up to date with
    the json file it generates in this repo.
  """
  def run(args) do
    arguments = %{
      input_file: Enum.at(args, 0, Data.file_path("content.csv")),
      output_file: Enum.at(args, 1, "fare_location_data.json"),
      geocode_fn: Enum.at(args, 2, &Fares.RetailLocations.Extractor.geocode/1)
    }
    arguments
    |> Map.get(:input_file)
    |> File.exists?
    |> start(arguments)
  end

  def start(false, %{input_file: input_file}) do
    Extractor.log "Could not fetch data -- no input file found at #{input_file}!", :error
    :error
  end
  def start(true, arguments) do
    {:ok, _} = Application.ensure_all_started(:fares)
    {:ok, _} = Application.ensure_all_started(:google_maps)

    {:ok, pid} = GenServer.start_link(Extractor, arguments)
    GenServer.call(pid, :start, 1000 * 60 * 5)
  end
end


defmodule Fares.RetailLocations.Extractor do
  use GenServer
  require Fares.RetailLocations.Location
  require Logger
  alias Fares.RetailLocations.{Location, Data}

  @moduledoc """
    Creates a json file using data extracted from `content.csv`. Can optionally take a custom path for the file to
    look for during testing. The contents of the file will be an array of maps containing data for locations where
    Fare media can be purchased.
  """

  @type api_fn :: {atom, atom}

  def init(args) do
    {:ok, args}
  end

  def handle_call(:start, parent, state) do
    :ok = start(state, parent)
    {:reply, :ok, state}
  end

  def log(data, method \\ nil)
  def log(data, :warn) do
    _ = Logger.warn(inspect(data))
    :ok
  end
  def log(data, _) when is_binary(data) do
    _ = Logger.info data
    :ok
  end

  @doc """
  Extracts fare sales location data from /priv/content.csv and writes it to a new file at the path provided.
  """
  @spec start(map, {pid, any}) :: :ok
  def start(%{geocode_fn: geocode_fn, input_file: input_file, output_file: output_file}, {parent, _}) do
    log "Extracting fare location data from #{input_file} to #{output_file}..."
    :ok = input_file
    |> File.stream!
    |> Enum.filter(&find_xml_string/1)
    |> Enum.map(&parse_location/1)
    |> Enum.map(&(get_lat_lng(&1, geocode_fn)))
    |> Poison.encode
    |> write_to_file(output_file)
    send parent, {:ok, output_file}
    :ok
  end

  @doc """
  Writes retail location data to a JSON file in apps/fares/priv.
  """
  @spec write_to_file({:ok, [Location.t]} | {:error, String.t}, String.t) :: :ok | {:error, String.t}
  def write_to_file({:ok, json_string}, output_file) do
    log "Writing data to #{output_file}"
    :ok = output_file
    |> Data.file_path
    |> File.write(json_string)
  end
  def write_to_file({:error, error}, _), do: {:error, error}

  @spec find_xml_string(String.t) :: boolean
  defp find_xml_string(string), do: String.match?(string, ~r/\<root\>.+Type_of_Agent.+\<\/root\>/)

  @doc """
    Takes a string of XML, parses it into a tuple, extracts data from that tuple, and returns the data as a map.
  """
  @spec parse_location(String.t) :: map
  def parse_location(string) do
    ~r/(\<root\>.+\<\/root\>)/
    |> Regex.split(string, include_captures: true)
    |> Enum.at(1)
    |> SweetXml.parse
    |> parse_xml
    |> Map.new
  end

  @type xml_text_tuple :: {:xmlText, [{atom, integer}], integer, list, String.t, :text}

  @type xml_element_tuple :: {:xmlElement, atom, atom, [], {atom, list, list}, list, integer, list,
                                           [xml_element_tuple | xml_text_tuple],
                                           list, String.t, atom}

  @spec parse_xml(xml_element_tuple) :: Keyword.t
  defp parse_xml({_, _, _, _, _, _, _, _, els, _, _, _}) do
    els
    |> parse_el
  end

  @spec parse_el([xml_element_tuple] | xml_element_tuple) :: [{atom, String.t}] | {atom, String.t}
  defp parse_el(els) when is_list(els), do: Enum.map(els, &parse_el/1)
  defp parse_el({:xmlElement, tag, _, _, _, _, _, _, els, _, _, _}), do: {downcase_key(tag), extract_text(els)}

  @spec parse_text_el([xml_text_tuple] | xml_text_tuple) :: String.t
  defp parse_text_el({:xmlElement, _, _, _, _, _, _, _, els, _, _, _}), do: extract_text(els)
  defp parse_text_el({:xmlText, [{_, _}|_], _, _, text, _}), do: text

  @spec downcase_key(atom) :: atom
  defp downcase_key(atom) do
    atom
    |> Atom.to_string
    |> String.downcase
    |> String.to_atom
  end

  @spec extract_text([xml_text_tuple]) :: String.t
  defp extract_text(els) do
    els
    |> Enum.map(&parse_text_el/1)
    |> Enum.join("")
  end

  @spec get_lat_lng(map, (String.t -> GoogleMaps.Geocode.t)) :: map
  def get_lat_lng(%{latitude: "", longitude: ""} = data, geocode_fn) do
    do_get_lat_lng(data, geocode_fn)
  end
  def get_lat_lng(%{latitude: lat, longitude: lng} = data, _)  do
    put_lat_lng([lat,lng], data)
  end

  defp do_get_lat_lng(%{location: street, city: city} = data, geocode_fn) do
    address = clean_street(street) <> ", " <> clean_city(city) <> " MA"
    log "Geocoding #{address}..."

    address
    |> geocode_fn.()
    |> handle_geocoding_response(data)
  end

  @spec clean_street(String.t) :: String.t
  defp clean_street(street) do
    street
    |> String.split("(")
    |> List.first
  end

  @spec clean_city(String.t) :: String.t
  defp clean_city(city) do
    city
    |> String.split("/")
    |> List.first
    |> String.split(", MA")
    |> List.first
  end

  @spec handle_geocoding_response({:ok, [map]}, map) :: map
  def handle_geocoding_response({:ok, [%{latitude: lat, longitude: lng}]}, data) do
    log "#{lat}, #{lng}"
    [lat,lng]
    |> put_lat_lng(data)
  end

  def handle_geocoding_response({:ok, addresses}, data) when length(addresses) > 1 do
    log "\nGot multiple results for address...  :::::  #{inspect data}", :warn
    log inspect(addresses), :warn
    put_lat_lng(["0.0","0.0"], data)
  end

  def handle_geocoding_response({:error, error, error_obj}, data) do
    log "\nNo google maps results found!  ::::::: #{error} #{inspect(error_obj)} :::::::   #{inspect data}", :warn
    put_lat_lng(["0.0","0.0"], data)
  end

  def geocode(address) do
    :timer.sleep(200)
    GoogleMaps.Geocode.geocode(address)
  end

  @spec put_lat_lng([String.t] | [float], map) :: map
  defp put_lat_lng([lat, lng], data) when is_float(lat) and is_float(lng) do
    data
    |> Map.put(:latitude, lat)
    |> Map.put(:longitude, lng)
  end
  defp put_lat_lng(coords, data) do
    coords
    |> Enum.map(&clean_coord_string/1)
    |> Enum.map(&String.to_float/1)
    |> Enum.map(&clean_coord_value/1)
    |> put_lat_lng(data)
  end

  @spec  clean_coord_string(String.t) :: String.t
  def clean_coord_string("," <> coord), do: coord
  def clean_coord_string(coord), do: coord

  def clean_coord_value(val) when val > 70, do: val * -1
  def clean_coord_value(val), do: val
end
