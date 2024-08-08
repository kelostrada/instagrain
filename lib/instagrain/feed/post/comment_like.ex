defmodule Instagrain.Feed.Post.CommentLike do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "post_comment_likes" do
    belongs_to :comment, Instagrain.Feed.Post.Comment
    belongs_to :user, Instagrain.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(comment_like, attrs) do
    comment_like
    |> cast(attrs, [:comment_id, :user_id])
    |> validate_required([:comment_id, :user_id])
    |> unique_constraint([:comment_id, :user_id])
  end
end
