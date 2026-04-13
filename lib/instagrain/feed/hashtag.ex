defmodule Instagrain.Feed.Hashtag do
  use Ecto.Schema
  import Ecto.Changeset

  schema "hashtags" do
    field :name, :string
    field :post_count, :integer, default: 0

    many_to_many :posts, Instagrain.Feed.Post, join_through: "post_hashtags"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(hashtag, attrs) do
    hashtag
    |> cast(attrs, [:name, :post_count])
    |> validate_required([:name])
    |> update_change(:name, &String.downcase/1)
    |> validate_format(:name, ~r/^[a-z0-9_]+$/)
    |> unique_constraint(:name)
  end
end
