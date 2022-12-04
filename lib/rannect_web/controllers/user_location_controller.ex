defmodule RannectWeb.UserLocationController do
  use RannectWeb, :controller

  alias Rannect.Users

  def updateLocation(conn, %{"lat" => lat, "long" => long, "temp" => temp, "user" => user_id}) do
    check_rannect_key = fetch_cookies(conn)

    # IO.puts("Below are cookies?")
    # IO.inspect(check_rannect_key.req_cookies)

    if !check_rannect_key.req_cookies["_rannect_key"] do
      json(conn, %{
        hacker: true,
        error: "Don't be oversmart! Hacking is bad. Unless you are pentesting"
      })
    end

    userLocation =
      Geonames.find_nearby_place_name(%{
        lat: lat,
        lng: long,
        radius: 10,
        maxRows: 1,
        username: "rannect"
      })

    # userLocation = %{
    #   "geonames" => [
    #     %{
    #       "adminCode1" => "09",
    #       "adminCodes1" => %{"ISO3166_2" => "GJ"},
    #       "adminName1" => "Gujarat",
    #       "countryCode" => "IN",
    #       "countryId" => "1269750",
    #       "countryName" => "India",
    #       "distance" => "0.22891",
    #       "fcl" => "P",
    #       "fclName" => "city, village,...",
    #       "fcode" => "PPL",
    #       "fcodeName" => "populated place",
    #       "geonameId" => 1_255_364,
    #       "lat" => "21.19594",
    #       "lng" => "72.83023",
    #       "name" => "Surat",
    #       "population" => 4_591_246,
    #       "toponymName" => "Surat"
    #     }
    #   ]
    # }

    userCountry = List.first(userLocation["geonames"], %{:countryName => "N/A"})["countryName"]
    userCity = List.first(userLocation["geonames"], %{:countryName => "N/A"})["name"]
    userState = List.first(userLocation["geonames"], %{:countryName => "N/A"})["adminName1"]

    userCountryCode =
      List.first(userLocation["geonames"], %{:countryName => "N/A"})["countryCode"]

    # IO.puts("userCountry : " <> userCountry)
    # IO.puts("userCity : " <> userCity)
    # IO.puts("userState : " <> userState)
    # IO.puts("userCountryCode : " <> userCountryCode)

    # IO.inspect("temp is " <> temp)

    if temp == "true" do
      user = Users.get_temp_user!(String.to_integer(user_id))

      Users.update_temp_location(user, %{
        country: userCountry,
        city: userCity,
        state: userState,
        country_code: userCountryCode,
        lat: lat,
        long: long
      })
    else
      user = Users.get_user!(String.to_integer(user_id))

      Users.update_location(user, %{
        country: userCountry,
        city: userCity,
        state: userState,
        country_code: userCountryCode,
        lat: lat,
        long: long
      })
    end

    json(conn, %{
      success: true
    })
  end
end
