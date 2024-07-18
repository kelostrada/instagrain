defmodule Instagrain.FeedFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Instagrain.Feed` context.
  """

  @doc """
  Generate a post.
  """
  def post_fixture(attrs \\ %{}) do
    {:ok, post} =
      attrs
      |> Enum.into(%{
        caption: "some caption",
        disable_comments: true,
        hide_likes: true,
        image: "some image",
        likes: 42,
        location_id: 42
      })
      |> Instagrain.Feed.create_post()

    post
  end
end
