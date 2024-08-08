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

  @doc """
  Generate a resource.
  """
  def resource_fixture(attrs \\ %{}) do
    {:ok, resource} =
      attrs
      |> Enum.into(%{
        alt: "some alt",
        file: "some file",
        type: :photo
      })
      |> Instagrain.Feed.create_resource()

    resource
  end

  @doc """
  Generate a like.
  """
  def like_fixture(attrs \\ %{}) do
    {:ok, like} =
      attrs
      |> Enum.into(%{})
      |> Instagrain.Feed.create_like()

    like
  end

  @doc """
  Generate a comment.
  """
  def comment_fixture(attrs \\ %{}) do
    {:ok, comment} =
      attrs
      |> Enum.into(%{
        comment: "some comment",
        likes: 42
      })
      |> Instagrain.Feed.create_comment()

    comment
  end

  @doc """
  Generate a comment_like.
  """
  def comment_like_fixture(attrs \\ %{}) do
    {:ok, comment_like} =
      attrs
      |> Enum.into(%{

      })
      |> Instagrain.Feed.create_comment_like()

    comment_like
  end
end
