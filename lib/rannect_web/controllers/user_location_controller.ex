defmodule RannectWeb.UserLocationController do
  use RannectWeb, :controller

  alias Rannect.Users

  def updateLocation(conn, %{"lat" => lat, "long" => long}) do
    # userLocation =
    #   Geonames.find_nearby_place_name(%{
    #     lat: lat,
    #     lng: long,
    #     radius: 10,
    #     maxRows: 1,
    #     username: "rannect"
    #   })
    user = conn.assigns.current_user

    userLocation = %{
      "geonames" => [
        %{
          "adminCode1" => "09",
          "adminCodes1" => %{"ISO3166_2" => "GJ"},
          "adminName1" => "Gujarat",
          "countryCode" => "IN",
          "countryId" => "1269750",
          "countryName" => "India",
          "distance" => "0.22891",
          "fcl" => "P",
          "fclName" => "city, village,...",
          "fcode" => "PPL",
          "fcodeName" => "populated place",
          "geonameId" => 1_255_364,
          "lat" => "21.19594",
          "lng" => "72.83023",
          "name" => "Surat",
          "population" => 4_591_246,
          "toponymName" => "Surat"
        }
      ]
    }

    userCountry = List.first(userLocation["geonames"], %{:countryName => "N/A"})["countryName"]
    userCity = List.first(userLocation["geonames"], %{:countryName => "N/A"})["name"]
    userState = List.first(userLocation["geonames"], %{:countryName => "N/A"})["adminName1"]

    userCountryCode =
      List.first(userLocation["geonames"], %{:countryName => "N/A"})["countryCode"]

    # IO.puts("userCountry : " <> userCountry)
    # IO.puts("userCity : " <> userCity)
    # IO.puts("userState : " <> userState)
    # IO.puts("userCountryCode : " <> userCountryCode)

    Users.update_location(user, %{
      country: userCountry,
      city: userCity,
      state: userState,
      country_code: userCountryCode,
      lat: lat,
      long: long
    })

    json(conn, %{
      "userCountry" => userCountry,
      "userCity" => userCity,
      "userState" => userState,
      "userCountryCode" => userCountryCode,
      "lat" => lat,
      "long" => long
    })
  end
end
