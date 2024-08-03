defmodule Instagrain.Feed.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :image, :string
    field :likes, :integer
    field :caption, :string
    field :location, :string, virtual: true
    field :location_id, :integer
    field :hide_likes, :boolean, default: false
    field :disable_comments, :boolean, default: false
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [
      :image,
      :likes,
      :caption,
      :location_id,
      :location,
      :hide_likes,
      :disable_comments,
      :user_id
    ])
    |> validate_required([:image, :likes, :hide_likes, :disable_comments, :user_id])
    |> validate_length(:caption, max: 2200)
  end
end
