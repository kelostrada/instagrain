defmodule Instagrain.Feed.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :image, :string
    field :likes, :integer
    field :caption, :string
    field :location_id, :integer
    field :hide_likes, :boolean, default: false
    field :disable_comments, :boolean, default: false
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:image, :likes, :caption, :location_id, :hide_likes, :disable_comments])
    |> validate_required([:image, :likes, :caption, :location_id, :hide_likes, :disable_comments])
  end
end
