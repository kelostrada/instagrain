defmodule Instagrain.Feed.Post.Save do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "post_saves" do
    belongs_to :post, Instagrain.Feed.Post
    belongs_to :user, Instagrain.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(save, attrs) do
    save
    |> cast(attrs, [:user_id, :post_id])
    |> validate_required([:user_id, :post_id])
    |> unique_constraint([:post_id, :user_id])
  end
end
