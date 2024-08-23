defmodule Instagrain.ProfilesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Instagrain.Profiles` context.
  """

  @doc """
  Generate a follow.
  """
  def follow_fixture(attrs \\ %{}) do
    {:ok, follow} =
      attrs
      |> Enum.into(%{

      })
      |> Instagrain.Profiles.create_follow()

    follow
  end
end
