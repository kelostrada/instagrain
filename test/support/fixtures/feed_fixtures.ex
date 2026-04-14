defmodule Instagrain.FeedFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Instagrain.Feed` context.
  """

  import Instagrain.AccountsFixtures

  @doc """
  Generate a post.
  """
  def post_fixture(attrs \\ %{}) do
    user = Map.get_lazy(attrs, :user, fn -> user_fixture() end)

    {:ok, post} =
      attrs
      |> Enum.into(%{
        caption: "some caption",
        disable_comments: false,
        hide_likes: false,
        likes: 0,
        user_id: user.id
      })
      |> Instagrain.Feed.create_post()

    post
  end

  @doc """
  Generate a resource.
  """
  def resource_fixture(attrs \\ %{}) do
    post = Map.get_lazy(attrs, :post, fn -> post_fixture() end)

    {:ok, resource} =
      attrs
      |> Enum.into(%{
        alt: "some alt",
        file: "some file",
        type: :photo,
        post_id: post.id
      })
      |> Instagrain.Feed.create_resource()

    resource
  end

  @doc """
  Generate a comment.
  """
  def comment_fixture(attrs \\ %{}) do
    user = Map.get_lazy(attrs, :user, fn -> user_fixture() end)
    post = Map.get_lazy(attrs, :post, fn -> post_fixture(%{user: user}) end)

    {:ok, comment} =
      attrs
      |> Enum.into(%{
        comment: "some comment",
        post_id: post.id,
        user_id: user.id
      })
      |> Instagrain.Feed.create_comment()

    comment
  end

  @doc """
  Generate a location.
  """
  def location_fixture(attrs \\ %{}) do
    {:ok, location} =
      attrs
      |> Enum.into(%{
        name: "Test City, Country #{System.unique_integer([:positive])}",
        address: "Some Region",
        lat: 54.35,
        lng: 18.65
      })
      |> Instagrain.Feed.find_or_create_location()

    location
  end
end
