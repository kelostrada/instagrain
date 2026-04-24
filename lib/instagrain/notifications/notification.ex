defmodule Instagrain.Notifications.Notification do
  use Ecto.Schema
  import Ecto.Changeset

  @types ~w(follow like comment like_comment)

  schema "notifications" do
    field :type, :string
    field :seen_at, :utc_datetime

    belongs_to :user, Instagrain.Accounts.User
    belongs_to :actor, Instagrain.Accounts.User
    belongs_to :post, Instagrain.Feed.Post
    belongs_to :comment, Instagrain.Feed.Post.Comment

    timestamps(type: :utc_datetime)
  end

  def types, do: @types

  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:user_id, :actor_id, :type, :post_id, :comment_id, :seen_at])
    |> validate_required([:user_id, :actor_id, :type])
    |> validate_inclusion(:type, @types)
    |> unique_constraint([:user_id, :actor_id, :type, :post_id, :comment_id],
      name: :notifications_uniqueness_index
    )
  end
end
