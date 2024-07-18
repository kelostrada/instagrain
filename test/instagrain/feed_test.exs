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

  describe "post_resources" do
    alias Instagrain.Feed.Post.Resource

    import Instagrain.FeedFixtures

    @invalid_attrs %{type: nil, file: nil, alt: nil}

    test "list_post_resources/0 returns all post_resources" do
      resource = resource_fixture()
      assert Feed.list_post_resources() == [resource]
    end

    test "get_resource!/1 returns the resource with given id" do
      resource = resource_fixture()
      assert Feed.get_resource!(resource.id) == resource
    end

    test "create_resource/1 with valid data creates a resource" do
      valid_attrs = %{type: :photo, file: "some file", alt: "some alt"}

      assert {:ok, %Resource{} = resource} = Feed.create_resource(valid_attrs)
      assert resource.type == :photo
      assert resource.file == "some file"
      assert resource.alt == "some alt"
    end

    test "create_resource/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Feed.create_resource(@invalid_attrs)
    end

    test "update_resource/2 with valid data updates the resource" do
      resource = resource_fixture()
      update_attrs = %{type: :video, file: "some updated file", alt: "some updated alt"}

      assert {:ok, %Resource{} = resource} = Feed.update_resource(resource, update_attrs)
      assert resource.type == :video
      assert resource.file == "some updated file"
      assert resource.alt == "some updated alt"
    end

    test "update_resource/2 with invalid data returns error changeset" do
      resource = resource_fixture()
      assert {:error, %Ecto.Changeset{}} = Feed.update_resource(resource, @invalid_attrs)
      assert resource == Feed.get_resource!(resource.id)
    end

    test "delete_resource/1 deletes the resource" do
      resource = resource_fixture()
      assert {:ok, %Resource{}} = Feed.delete_resource(resource)
      assert_raise Ecto.NoResultsError, fn -> Feed.get_resource!(resource.id) end
    end

    test "change_resource/1 returns a resource changeset" do
      resource = resource_fixture()
      assert %Ecto.Changeset{} = Feed.change_resource(resource)
    end
  end
end
