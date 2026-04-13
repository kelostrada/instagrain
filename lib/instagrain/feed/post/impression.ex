defmodule Instagrain.Feed.Post.Impression do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "post_impressions" do
    belongs_to :user, Instagrain.Accounts.User
    belongs_to :post, Instagrain.Feed.Post
    field :view_count, :integer, default: 1
    field :last_seen_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(impression, attrs) do
    impression
    |> cast(attrs, [:user_id, :post_id, :view_count, :last_seen_at])
    |> validate_required([:user_id, :post_id, :last_seen_at])
    |> unique_constraint([:user_id, :post_id], name: :post_impressions_pkey)
  end
end
