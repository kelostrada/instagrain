defmodule Instagrain.Feed.PostHashtag do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "post_hashtags" do
    belongs_to :post, Instagrain.Feed.Post
    belongs_to :hashtag, Instagrain.Feed.Hashtag

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(post_hashtag, attrs) do
    post_hashtag
    |> cast(attrs, [:post_id, :hashtag_id])
    |> validate_required([:post_id, :hashtag_id])
    |> unique_constraint([:post_id, :hashtag_id], name: :post_hashtags_pkey)
  end
end
