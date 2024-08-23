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
    |> Repo.preload([:posts])
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

      iex> delete_follow(follow)
      {:ok, %Follow{}}

      iex> delete_follow(follow)
      {:error, %Ecto.Changeset{}}

  """
  def delete_follow(%Follow{} = follow) do
    Repo.delete(follow)
  end
end
