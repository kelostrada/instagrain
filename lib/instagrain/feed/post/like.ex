defmodule Instagrain.Feed.Post.Like do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "post_likes" do
    belongs_to :post, Instagrain.Feed.Post
    belongs_to :user, Instagrain.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(like, attrs) do
    like
    |> cast(attrs, [:user_id, :post_id])
    |> validate_required([:user_id, :post_id])
    |> unique_constraint([:post_id, :user_id])
  end
end
