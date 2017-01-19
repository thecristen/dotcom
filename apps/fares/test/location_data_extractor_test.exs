defmodule Fares.RetailLocationsDataExtractorTest do
  use ExUnit.Case, async: false

  alias GoogleMaps.Geocode.Address
  alias Fares.RetailLocations.{Location, Data, Extractor}

  @lat 42.637261
  @lng -72.18372
  @test_output_file "fare_locations_test.json"
  @test_output_path @test_output_file |> Data.file_path
  @test_input_path "content.csv" |> Data.file_path

  describe "CSV Data Extractor:" do
    test "does not run if file is missing" do
      assert :error == Mix.Tasks.Fares.Locations.run ["nonexistant_file.csv"]
    end

    test "writes extracted data to a valid json file" do
      make_test_file()
      location = %Location{location: "10 Park Plaza", city: "Boston"}
      refute File.exists? @test_output_path

      location
      |> Poison.encode
      |> Extractor.write_to_file(@test_output_file)

      assert File.exists? @test_output_path

      expected = location
      |> Map.from_struct
      |> Enum.map(fn {k,v} -> {Atom.to_string(k), v} end)
      |> Map.new

      written = @test_output_path
      |> File.read!
      |> Poison.decode!

      assert written == expected
      remove_test_files()
    end

    test "extracts data from content.csv" do
      make_test_file()
      assert :ok = run_mix_task()
      @test_output_file
      |> Data.get
      |> Enum.each(fn %Location{latitude: lat, longitude: lng} ->
        assert is_float(lat)
        assert is_float(lng)
      end)
      remove_test_files()
    end

    test "logs information" do
      Logger.configure(level: :info)
      string = "testing logger"
      assert ExUnit.CaptureLog.capture_log([], (fn -> Extractor.log(string, :warn) end)) =~ string
      assert ExUnit.CaptureLog.capture_log([], (fn -> Extractor.log(string, "log test") end)) =~ string
      Logger.configure(level: :warn)
    end

    test "geocodes locations that do not have latitude/longitude" do
      geocoded = Extractor.get_lat_lng %{latitude: "", longitude: "", location: "10 Park Plaza", city: "Boston"}, nil
      assert geocoded == %{city: "Boston", latitude: 42.3515322, location: "10 Park Plaza", longitude: -71.0668452}
    end

    test "does not geocode locations that already have latitude/longitude" do
      geocoded = Extractor.get_lat_lng %{latitude: "42.3515322", longitude: "-71.0668452"}, nil
      assert %{latitude: 42.3515322, longitude: -71.0668452} = geocoded
    end

    @tag :capture_log
    test "sets lat/lng to 0.0/0.0 for addresses that return multiple results" do
      expected = %{city: "Boston", latitude: 0.0, location: "10 Park", longitude: 0.0}
      assert Extractor.get_lat_lng(%{location: "10 Park", city: "Boston", latitude: "", longitude: ""}, nil) == expected
    end

    @tag :capture_log
    test "sets lat/lng to 0.0/0.0 for addresses that return zero results" do
      expected = %{city: "", latitude: 0.0, location: "Not a real street", longitude: 0.0}
      assert Extractor.get_lat_lng(%{location: "Not a real street", city: "", latitude: "", longitude: ""}, nil) == expected
    end

    test "cleans data before attempting to geocode" do
      bad_coords = %{location: "10 Park Plaza", city: "Boston", latitude: ",42.3515322", longitude: "71.0668452"}
      expected = %{location: "10 Park Plaza", city: "Boston", latitude: 42.3515322, longitude: -71.0668452}
      assert expected == Extractor.get_lat_lng(bad_coords, nil)
    end

    test "can run and finish" do
      make_test_file()
      assert :ok = run_mix_task()
      remove_test_files()
    end

    def make_test_file, do: File.write! @test_input_path, fare_location_data()

    def remove_test_files do
      File.rm @test_input_path
      File.rm @test_output_path
    end

    def run_mix_task, do: Mix.Tasks.Fares.Locations.run [@test_input_path, @test_output_file, {__MODULE__, :bypass_api}]

    def bypass_api(string) do
      {:ok, [%Address{latitude: @lat, longitude: @lng, formatted: string}]}
    end

    def fare_location_data do
      """
        1505,1032, Location with multiple results, "<root><City>Boston</City><Type_of_Agent>B</Type_of_Agent><Agent>Location with multiple map results</Agent><Street_Number>10</Street_Number><Location>10 Huntington Ave.</Location><Hours_of_Operation>M-F 8:00 a.m. to 5:00 p.m.</Hours_of_Operation><Dates_Sold>All fare media is sold daily.  Monthly passes are sold starting the 15th of the prior month until the 14th of the current month.</Dates_Sold><Types_of_passes_on_sale>Bus, Subway, Combo, Combo Plus, Express Bus zone 1 &amp; 2, Senior Pass.</Types_of_passes_on_sale><Method_of_Payment>Cash and Commuter Checks.</Method_of_Payment><Type_of_passes_on_sale2007>Stored Value (up to $100.00), all MBTA Monthly passes (excluding Student), all Commuter Rail Tickets including Ten and Twelve Ride, 1-Day LinkPass, 7-Day LinkPass.</Type_of_passes_on_sale2007><Method_of_payment2007>Cash and Commuter Checks. This location services <strong>CharlieCards</strong> and CharlieTickets.</Method_of_payment2007><Telephone>617-720-0553</Telephone><Fax /><Name /><User /><View_onMap_sales /><Latitude /><Longitude /></root>",A,2006-10-03 16:51:00 +0000,O&#39; Neill,Lynne,,2008-06-13 08:19:13 +0000,271,206,1,206,1,206,0,Patriot News - Number 28,1,2006-10-03 16:45:00 +0000,"e  Boston/Faneuil Hall Marketplace B Patriot News 28 28 State St M-F 8:00 a.m to 5:00 p.m All fare media is sold daily.  Monthly passes are sold starting the 15th of the prior month until the 14th of the current month Bus Subway Combo Combo Plus Express Bus zone 1 &amp; 2 Senior Pass Cash and Commuter Checks Stored Value (up to $100.00) all MBTA Monthly passes (excluding Student) all Commuter Rail Tickets including Ten and Twelve Ride 1-Day LinkPass 7-Day LinkPass Cash and Commuter Checks.  This location services CharlieCards and CharlieTickets 617-720-0553    http://www.google.com/maps?f=q&amp;hl=en&amp;q=28+state+street.+boston,+MA&amp;ie=UTF8&amp;z=15&amp;ll=42.360066,-71.042404&amp;spn=0.014524,0.042443&amp;om=1&amp;iwloc=addr 42.360066 -71.042404   Patriot News - Number 28  e",2008-06-13 08:20:00 +0000,3,<null>,1,1,0,,,16,1,,0,<null>,<null>,0,2008-06-13 08:19:13 +0000,<null>
        1505,1032, Location with no map results, "<root><City>Boston</City><Type_of_Agent>B</Type_of_Agent><Agent>Location with no map results</Agent><Street_Number>10</Street_Number><Location>10 Vague St.</Location><Hours_of_Operation>M-F 8:00 a.m. to 5:00 p.m.</Hours_of_Operation><Dates_Sold>All fare media is sold daily.  Monthly passes are sold starting the 15th of the prior month until the 14th of the current month.</Dates_Sold><Types_of_passes_on_sale>Bus, Subway, Combo, Combo Plus, Express Bus zone 1 &amp; 2, Senior Pass.</Types_of_passes_on_sale><Method_of_Payment>Cash and Commuter Checks.</Method_of_Payment><Type_of_passes_on_sale2007>Stored Value (up to $100.00), all MBTA Monthly passes (excluding Student), all Commuter Rail Tickets including Ten and Twelve Ride, 1-Day LinkPass, 7-Day LinkPass.</Type_of_passes_on_sale2007><Method_of_payment2007>Cash and Commuter Checks. This location services <strong>CharlieCards</strong> and CharlieTickets.</Method_of_payment2007><Telephone>617-720-0553</Telephone><Fax /><Name /><User /><View_onMap_sales /><Latitude /><Longitude /></root>",A,2006-10-03 16:51:00 +0000,O&#39; Neill,Lynne,,2008-06-13 08:19:13 +0000,271,206,1,206,1,206,0,Patriot News - Number 28,1,2006-10-03 16:45:00 +0000,"e  Boston/Faneuil Hall Marketplace B Patriot News 28 28 State St M-F 8:00 a.m to 5:00 p.m All fare media is sold daily.  Monthly passes are sold starting the 15th of the prior month until the 14th of the current month Bus Subway Combo Combo Plus Express Bus zone 1 &amp; 2 Senior Pass Cash and Commuter Checks Stored Value (up to $100.00) all MBTA Monthly passes (excluding Student) all Commuter Rail Tickets including Ten and Twelve Ride 1-Day LinkPass 7-Day LinkPass Cash and Commuter Checks.  This location services CharlieCards and CharlieTickets 617-720-0553    http://www.google.com/maps?f=q&amp;hl=en&amp;q=28+state+street.+boston,+MA&amp;ie=UTF8&amp;z=15&amp;ll=42.360066,-71.042404&amp;spn=0.014524,0.042443&amp;om=1&amp;iwloc=addr 42.360066 -71.042404   Patriot News - Number 28  e",2008-06-13 08:20:00 +0000,3,<null>,1,1,0,,,16,1,,0,<null>,<null>,0,2008-06-13 08:19:13 +0000,<null>
        1506,1033,Patriot News - Number 28,"<root><City>Boston/Faneuil Hall Marketplace</City><Type_of_Agent>B</Type_of_Agent><Agent>Patriot News</Agent><Street_Number>28</Street_Number><Location>28 State St.</Location><Hours_of_Operation>M-F 8:00 a.m. to 5:00 p.m.</Hours_of_Operation><Dates_Sold>All fare media is sold daily.  Monthly passes are sold starting the 15th of the prior month until the 14th of the current month.</Dates_Sold><Types_of_passes_on_sale>Bus, Subway, Combo, Combo Plus, Express Bus zone 1 &amp; 2, Senior Pass.</Types_of_passes_on_sale><Method_of_Payment>Cash and Commuter Checks.</Method_of_Payment><Type_of_passes_on_sale2007>Stored Value (up to $100.00), all MBTA Monthly passes (excluding Student), all Commuter Rail Tickets including Ten and Twelve Ride, 1-Day LinkPass, 7-Day LinkPass.</Type_of_passes_on_sale2007><Method_of_payment2007>Cash and Commuter Checks. This location services <strong>CharlieCards</strong> and CharlieTickets.</Method_of_payment2007><Telephone>617-720-0553</Telephone><Fax /><Name /><User /><View_onMap_sales>http://www.google.com/maps?f=q&amp;hl=en&amp;q=28+state+street.+boston,+MA&amp;ie=UTF8&amp;z=15&amp;ll=42.360066,-71.042404&amp;spn=0.014524,0.042443&amp;om=1&amp;iwloc=addr</View_onMap_sales><Latitude>42.360066</Latitude><Longitude>-71.042404</Longitude></root>",A,2006-10-03 16:51:00 +0000,O&#39; Neill,Lynne,,2008-06-13 08:19:13 +0000,271,206,1,206,1,206,0,Patriot News - Number 28,1,2006-10-03 16:45:00 +0000,"e  Boston/Faneuil Hall Marketplace B Patriot News 28 28 State St M-F 8:00 a.m to 5:00 p.m All fare media is sold daily.  Monthly passes are sold starting the 15th of the prior month until the 14th of the current month Bus Subway Combo Combo Plus Express Bus zone 1 &amp; 2 Senior Pass Cash and Commuter Checks Stored Value (up to $100.00) all MBTA Monthly passes (excluding Student) all Commuter Rail Tickets including Ten and Twelve Ride 1-Day LinkPass 7-Day LinkPass Cash and Commuter Checks.  This location services CharlieCards and CharlieTickets 617-720-0553    http://www.google.com/maps?f=q&amp;hl=en&amp;q=28+state+street.+boston,+MA&amp;ie=UTF8&amp;z=15&amp;ll=42.360066,-71.042404&amp;spn=0.014524,0.042443&amp;om=1&amp;iwloc=addr 42.360066 -71.042404   Patriot News - Number 28  e",2008-06-13 08:20:00 +0000,3,<null>,1,1,0,,,16,1,,0,<null>,<null>,0,2008-06-13 08:19:13 +0000,<null>
        1508,1033,"302017: Star Market - 49 White Street, Cambridge","<root><City>Cambridge</City><Type_of_Agent>B</Type_of_Agent><Agent>Star Market</Agent><Street_Number>49</Street_Number><Location>49 White St. (Porter Square)</Location><Hours_of_Operation>Mon. - Sat. 8:00 a.m. to 10:00 p.m.</Hours_of_Operation><Dates_Sold>All fare media is sold daily. Monthly passes are sold starting the 15th of the prior month until the 14th of the current month.</Dates_Sold><Types_of_passes_on_sale><span>Stored Value (up to $100.00), all MBTA Monthly passes (excluding student), All Commuter Rail Tickets including Ten Ride (full and half fare), 1-Day LinkPass, 7-Day LinkPass. </span></Types_of_passes_on_sale><Method_of_Payment>Cash and Commuter Checks. This location services <b>CharlieCards</b> and CharlieTickets.</Method_of_Payment><Type_of_passes_on_sale2007>Stored Value (up to $100.00), all MBTA Monthly passes (excluding student), All Commuter Rail Tickets including Ten Ride (full and half fare), 1-Day LinkPass, 7-Day LinkPass.</Type_of_passes_on_sale2007><Method_of_payment2007>Cash and Commuter Checks. This location services <b>CharlieCards</b> and CharlieTickets.</Method_of_payment2007><Telephone></Telephone><Fax></Fax><Name></Name><User></User><View_onMap_sales>http://www.google.com/maps?f=q&amp;hl=en&amp;q=49+White+St.,+cambridge,+ma&amp;ie=UTF8&amp;z=15&amp;ll=42.390406,-71.117764&amp;spn=0.01477,0.043001&amp;om=1&amp;iwloc=addr</View_onMap_sales><Latitude>42.390406</Latitude><Longitude>-71.117764</Longitude></root>",A,2006-10-03 16:51:01 +0000,O&#39; Neill,Lynne,,2012-07-05 10:46:28 +0000,271,206,1,206,1,206,0,<p>Shaw's Supermarket - Number 49</p>,1,2006-10-03 16:45:00 +0000,"e CambridgeBStar Market4949 White St (Porter Square)Mon - Sat. 8:00 a.m to 10:00 p.m.All fare media is sold daily Monthly passes are sold starting the 15th of the prior month until the 14th of the current month.Stored Value (up to $100.00) all MBTA Monthly passes (excluding student) All Commuter Rail Tickets including Ten Ride (full and half fare) 1-Day LinkPass 7-Day LinkPass Cash and Commuter Checks This location services CharlieCards and CharlieTickets.Stored Value (up to $100.00) all MBTA Monthly passes (excluding student) All Commuter Rail Tickets including Ten Ride (full and half fare) 1-Day LinkPass 7-Day LinkPass.Cash and Commuter Checks This location services CharlieCards and CharlieTickets.http://www.google.com/maps?f=q&hl=en&q=49+White+St.,+cambridge,+ma&ie=UTF8&z=15&ll=42.390406,-71.117764&spn=0.01477,0.043001&om=1&iwloc=addr42.390406-71.117764 Shaw's Supermarket - Number 49 e",<null>,1,<null>,1,1,0,,,16,1,,0,<null>,<null>,0,2012-07-05 10:46:28 +0000,<null>
        1510,1033,Consignment: White Hen Pantry - Number 56,"<root><City>Haverhill</City><Type_of_Agent>B</Type_of_Agent><Agent>White Hen Pantry</Agent><Street_Number>56</Street_Number><Location>56 River St.</Location><Hours_of_Operation>Sun - Sat 5:00 a.m. to 9:00 p.m.</Hours_of_Operation><Dates_Sold>Monthly passes are sold the last ten and the first ten calendar days of each month. All other fare media is sold daily.</Dates_Sold><Types_of_passes_on_sale>Commuter Rail Zone 8; Tickets: One-Way, One-Way Half Fare, 10 Ride Half-Fare, 12 Ride, Family Fare. <strong>Effective January 2007</strong> all new Fare Media sold including CharlieCards.</Types_of_passes_on_sale><Method_of_Payment>Cash Only</Method_of_Payment><Type_of_passes_on_sale2007>Stored Value (up to $100.00), all MBTA Monthly passes (excluding student), all Commuter Rail Tickets including Ten Ride and Twelve Ride, 1-Day LinkPass, 7-Day LinkPass.</Type_of_passes_on_sale2007><Method_of_payment2007>Cash and Commuter Checks</Method_of_payment2007><Telephone /><Fax /><Name /><User /><View_onMap_sales>http://www.google.com/maps?f=q&amp;hl=en&amp;q=56+River+St,+haverhill,+ma&amp;ie=UTF8&amp;z=15&amp;ll=42.771778,-71.088367&amp;spn=0.014901,0.042915&amp;t=h&amp;om=1&amp;iwloc=addr</View_onMap_sales><Latitude>42.771778</Latitude><Longitude>-71.088367</Longitude></root>",A,2006-10-03 16:51:02 +0000,O&#39; Neill,Lynne,,2009-01-06 14:08:52 +0000,271,206,1,206,1,206,0,White Hen Pantry - Number 56,1,2006-10-03 16:45:00 +0000,"e  Haverhill B White Hen Pantry 56 56 River St Sun - Sat 5:00 a.m to 9:00 p.m Monthly passes are sold the last ten and the first ten calendar days of each month All other fare media is sold daily Commuter Rail Zone 8; Tickets One-Way One-Way Half Fare 10 Ride Half-Fare 12 Ride Family Fare Effective January 2007 all new Fare Media sold including CharlieCards Cash Only Stored Value (up to $100.00) all MBTA Monthly passes (excluding student) all Commuter Rail Tickets including Ten Ride and Twelve Ride 1-Day LinkPass 7-Day LinkPass Cash and Commuter Checks     http://www.google.com/maps?f=q&amp;hl=en&amp;q=56+River+St,+haverhill,+ma&amp;ie=UTF8&amp;z=15&amp;ll=42.771778,-71.088367&amp;spn=0.014901,0.042915&amp;t=h&amp;om=1&amp;iwloc=addr 42.771778 -71.088367   White Hen Pantry - Number 56  e",2009-01-06 14:10:00 +0000,3,<null>,1,2,0,,,16,1,,0,<null>,<null>,0,2009-01-06 14:08:52 +0000,<null>
        1512,1033,Consignment: Congress Card - Number 230,"<root><City>Boston/Financial District</City><Type_of_Agent>B</Type_of_Agent><Agent>Congress Card</Agent><Street_Number>230</Street_Number><Location>230 Congress St.</Location><Hours_of_Operation>M-F 7:00 a.m. to 5:00 p.m.</Hours_of_Operation><Dates_Sold>Monthly passes are sold the last four and the first four business days of each month.</Dates_Sold><Types_of_passes_on_sale>Bus, Subway, Combo, Combo Plus, Express Bus Zone 1 &amp; 2.</Types_of_passes_on_sale><Method_of_Payment>Cash Only</Method_of_Payment><Type_of_passes_on_sale2007>Local Bus, LinkPass, Zone 1A, Inner Express and Outer Express</Type_of_passes_on_sale2007><Method_of_payment2007>Cash and Commuter Checks</Method_of_payment2007><Telephone /><Fax /><Name /><User /><View_onMap_sales>http://www.google.com/maps?f=q&amp;hl=en&amp;q=230+Congress+St+boston,+ma&amp;ie=UTF8&amp;z=15&amp;ll=42.35569,-71.054249&amp;spn=0.014525,0.042443&amp;om=1&amp;iwloc=addr</View_onMap_sales><Latitude>42.35569</Latitude><Longitude>-71.054249</Longitude></root>",A,2006-10-03 16:51:04 +0000,O&#39; Neill,Lynne,,2009-05-26 10:48:18 +0000,271,206,1,206,1,206,0,Congress Card - Number 230,1,2006-10-03 16:45:00 +0000,"e  Boston/Financial District B Congress Card 230 230 Congress St M-F 7:00 a.m to 5:00 p.m Monthly passes are sold the last four and the first four business days of each month Bus Subway Combo Combo Plus Express Bus Zone 1 &amp; 2 Cash Only Local Bus LinkPass Zone 1A Inner Express and Outer Express Cash and Commuter Checks     http://www.google.com/maps?f=q&amp;hl=en&amp;q=230+Congress+St+boston,+ma&amp;ie=UTF8&amp;z=15&amp;ll=42.35569,-71.054249&amp;spn=0.014525,0.042443&amp;om=1&amp;iwloc=addr 42.35569 -71.054249   Congress Card - Number 230  e",2009-05-26 10:50:00 +0000,3,<null>,1,1,0,,,16,1,,0,<null>,<null>,0,2009-05-26 10:48:18 +0000,<null>
      """
    end
  end

end
