defmodule Instagrain.Feed.Post.Comment do
  use Ecto.Schema
  alias Instagrain.Accounts.User
  alias Instagrain.Feed.Post
  alias Instagrain.Feed.Post.Comment
  alias Instagrain.Feed.Post.CommentLike
  import Ecto.Changeset

  schema "post_comments" do
    field :comment, :string
    field :likes, :integer, default: 0
    belongs_to :post, Post
    belongs_to :user, User
    belongs_to :reply_to, Comment
    has_many :replies, Comment, foreign_key: :reply_to_id, references: :id
    has_many :comment_likes, CommentLike, foreign_key: :comment_id, references: :id

    field :liked_by_current_user?, :boolean, virtual: true

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:comment, :likes, :post_id, :user_id, :reply_to_id])
    |> validate_required([:comment, :post_id, :user_id])
  end
end
