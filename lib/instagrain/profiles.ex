defmodule Instagrain.Profiles do
  @moduledoc """
  The Profiles context.
  """

  import Ecto.Query, warn: false
  alias Instagrain.Repo

  # alias Instagrain.Feed.Post
  alias Instagrain.Accounts.User
  alias Instagrain.Profiles.Follow

  def get_profile(username) do
    from(u in User, where: u.username == ^username)
    |> Repo.one()
    |> Repo.preload([:followers, :followings, :posts])
  end

  @doc """
  Creates a follow.

  ## Examples

      iex> follow_user(1, 2)
      {:ok, %Follow{}}

      iex> follow_user(1, 1)
      {:error, %Ecto.Changeset{}}

  """
  def follow_user(user_id, follow_id) do
    %Follow{}
    |> Follow.changeset(%{user_id: user_id, follow_id: follow_id})
    |> Repo.insert()
  end

  @doc """
  Deletes a follow.

  ## Examples

      iex> unfollow_user(user_id, follow_id)
      {:ok, %Follow{}}

      iex> delete_follow(follow)
      {:error, %Ecto.Changeset{}}

  """
  def unfollow_user(user_id, follow_id) do
    case from(f in Follow, where: f.user_id == ^user_id and f.follow_id == ^follow_id)
         |> Repo.delete_all() do
      {1, _} -> :ok
      _ -> {:error, :not_found}
    end
  end
end
