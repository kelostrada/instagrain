defmodule Instagrain.ProfilesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Instagrain.Profiles` context.
  """

  import Instagrain.AccountsFixtures

  @doc """
  Generate a follow relationship between two users.
  """
  def follow_fixture(attrs \\ %{}) do
    user = Map.get_lazy(attrs, :user, fn -> user_fixture() end)
    followed_user = Map.get_lazy(attrs, :followed_user, fn -> user_fixture() end)

    {:ok, follow} =
      Instagrain.Profiles.follow_user(
        Map.get(attrs, :user_id, user.id),
        Map.get(attrs, :follow_id, followed_user.id)
      )

    follow
  end
end
