defmodule Instagrain.FeedTest do
  use Instagrain.DataCase

  alias Instagrain.Feed

  describe "posts" do
    alias Instagrain.Feed.Post

    import Instagrain.FeedFixtures

    @invalid_attrs %{image: nil, likes: nil, caption: nil, location_id: nil, hide_likes: nil, disable_comments: nil}

    test "list_posts/0 returns all posts" do
      post = post_fixture()
      assert Feed.list_posts() == [post]
    end

    test "get_post!/1 returns the post with given id" do
      post = post_fixture()
      assert Feed.get_post!(post.id) == post
    end

    test "create_post/1 with valid data creates a post" do
      valid_attrs = %{image: "some image", likes: 42, caption: "some caption", location_id: 42, hide_likes: true, disable_comments: true}

      assert {:ok, %Post{} = post} = Feed.create_post(valid_attrs)
      assert post.image == "some image"
      assert post.likes == 42
      assert post.caption == "some caption"
      assert post.location_id == 42
      assert post.hide_likes == true
      assert post.disable_comments == true
    end

    test "create_post/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Feed.create_post(@invalid_attrs)
    end

    test "update_post/2 with valid data updates the post" do
      post = post_fixture()
      update_attrs = %{image: "some updated image", likes: 43, caption: "some updated caption", location_id: 43, hide_likes: false, disable_comments: false}

      assert {:ok, %Post{} = post} = Feed.update_post(post, update_attrs)
      assert post.image == "some updated image"
      assert post.likes == 43
      assert post.caption == "some updated caption"
      assert post.location_id == 43
      assert post.hide_likes == false
      assert post.disable_comments == false
    end

    test "update_post/2 with invalid data returns error changeset" do
      post = post_fixture()
      assert {:error, %Ecto.Changeset{}} = Feed.update_post(post, @invalid_attrs)
      assert post == Feed.get_post!(post.id)
    end

    test "delete_post/1 deletes the post" do
      post = post_fixture()
      assert {:ok, %Post{}} = Feed.delete_post(post)
      assert_raise Ecto.NoResultsError, fn -> Feed.get_post!(post.id) end
    end

    test "change_post/1 returns a post changeset" do
      post = post_fixture()
      assert %Ecto.Changeset{} = Feed.change_post(post)
    end
  end
end
