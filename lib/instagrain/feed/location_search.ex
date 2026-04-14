defmodule Instagrain.Feed.LocationSearch do
  @moduledoc """
  Searches for locations using the Photon geocoding API (OpenStreetMap data).
  """

  @photon_url "https://photon.komoot.io/api/"

  def search(query) when byte_size(query) < 2, do: []

  def search(query) do
    url = "#{@photon_url}?q=#{URI.encode(query)}&limit=5&lang=en"

    case Finch.build(:get, url) |> Finch.request(Instagrain.Finch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        body
        |> Jason.decode!()
        |> Map.get("features", [])
        |> Enum.map(&parse_feature/1)
        |> Enum.uniq_by(& &1.name)

      _ ->
        []
    end
  end

  defp parse_feature(%{"properties" => props, "geometry" => geometry}) do
    name = build_name(props)
    address = build_address(props)
    [lng, lat] = Map.get(geometry, "coordinates", [nil, nil])

    %{name: name, address: address, lat: lat, lng: lng}
  end

  defp parse_feature(_), do: %{name: "Unknown", address: nil, lat: nil, lng: nil}

  defp build_name(props) do
    city = props["city"] || props["name"] || props["county"]
    country = props["country"]

    case {city, country} do
      {nil, nil} -> props["name"] || "Unknown"
      {nil, c} -> c
      {n, nil} -> n
      {n, c} -> "#{n}, #{c}"
    end
  end

  defp build_address(props) do
    parts =
      [props["street"], props["district"], props["state"]]
      |> Enum.reject(&is_nil/1)

    if parts == [], do: nil, else: Enum.join(parts, ", ")
  end
end
