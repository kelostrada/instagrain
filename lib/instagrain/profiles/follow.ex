defmodule Instagrain.Profiles.Follow do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "follows" do
    belongs_to :user, Instagrain.Accounts.User
    belongs_to :follow, Instagrain.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(follow, attrs) do
    follow
    |> cast(attrs, [:user_id, :follow_id])
    |> validate_required([:user_id, :follow_id])
    |> unique_constraint([:user_id, :follow_id])
  end
end
