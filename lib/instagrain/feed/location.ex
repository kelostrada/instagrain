defmodule Instagrain.Feed.Location do
  use Ecto.Schema
  import Ecto.Changeset

  schema "locations" do
    field :name, :string
    field :address, :string
    field :lat, :float
    field :lng, :float

    timestamps(type: :utc_datetime)
  end

  def changeset(location, attrs) do
    location
    |> cast(attrs, [:name, :address, :lat, :lng])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
