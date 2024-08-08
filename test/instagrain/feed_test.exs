defmodule Instagrain.FeedTest do
  use Instagrain.DataCase

  alias Instagrain.Feed

  describe "posts" do
    alias Instagrain.Feed.Post

    import Instagrain.FeedFixtures

    @invalid_attrs %{
      image: nil,
      likes: nil,
      caption: nil,
      location_id: nil,
      hide_likes: nil,
      disable_comments: nil
    }

    test "list_posts/0 returns all posts" do
      post = post_fixture()
      assert Feed.list_posts() == [post]
    end

    test "get_post!/1 returns the post with given id" do
      post = post_fixture()
      assert Feed.get_post!(post.id) == post
    end

    test "create_post/1 with valid data creates a post" do
      valid_attrs = %{
        image: "some image",
        likes: 42,
        caption: "some caption",
        location_id: 42,
        hide_likes: true,
        disable_comments: true
      }

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

      update_attrs = %{
        image: "some updated image",
        likes: 43,
        caption: "some updated caption",
        location_id: 43,
        hide_likes: false,
        disable_comments: false
      }

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

  describe "post_likes" do
    alias Instagrain.Feed.Post.Like

    import Instagrain.FeedFixtures

    @invalid_attrs %{}

    test "list_post_likes/0 returns all post_likes" do
      like = like_fixture()
      assert Feed.list_post_likes() == [like]
    end

    test "get_like!/1 returns the like with given id" do
      like = like_fixture()
      assert Feed.get_like!(like.id) == like
    end

    test "create_like/1 with valid data creates a like" do
      valid_attrs = %{}

      assert {:ok, %Like{} = like} = Feed.create_like(valid_attrs)
    end

    test "create_like/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Feed.create_like(@invalid_attrs)
    end

    test "update_like/2 with valid data updates the like" do
      like = like_fixture()
      update_attrs = %{}

      assert {:ok, %Like{} = like} = Feed.update_like(like, update_attrs)
    end

    test "update_like/2 with invalid data returns error changeset" do
      like = like_fixture()
      assert {:error, %Ecto.Changeset{}} = Feed.update_like(like, @invalid_attrs)
      assert like == Feed.get_like!(like.id)
    end

    test "delete_like/1 deletes the like" do
      like = like_fixture()
      assert {:ok, %Like{}} = Feed.delete_like(like)
      assert_raise Ecto.NoResultsError, fn -> Feed.get_like!(like.id) end
    end

    test "change_like/1 returns a like changeset" do
      like = like_fixture()
      assert %Ecto.Changeset{} = Feed.change_like(like)
    end
  end

  describe "post_comments" do
    alias Instagrain.Feed.Post.Comment

    import Instagrain.FeedFixtures

    @invalid_attrs %{comment: nil, likes: nil}

    test "list_post_comments/0 returns all post_comments" do
      comment = comment_fixture()
      assert Feed.list_post_comments() == [comment]
    end

    test "get_comment!/1 returns the comment with given id" do
      comment = comment_fixture()
      assert Feed.get_comment!(comment.id) == comment
    end

    test "create_comment/1 with valid data creates a comment" do
      valid_attrs = %{comment: "some comment", likes: 42}

      assert {:ok, %Comment{} = comment} = Feed.create_comment(valid_attrs)
      assert comment.comment == "some comment"
      assert comment.likes == 42
    end

    test "create_comment/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Feed.create_comment(@invalid_attrs)
    end

    test "update_comment/2 with valid data updates the comment" do
      comment = comment_fixture()
      update_attrs = %{comment: "some updated comment", likes: 43}

      assert {:ok, %Comment{} = comment} = Feed.update_comment(comment, update_attrs)
      assert comment.comment == "some updated comment"
      assert comment.likes == 43
    end

    test "update_comment/2 with invalid data returns error changeset" do
      comment = comment_fixture()
      assert {:error, %Ecto.Changeset{}} = Feed.update_comment(comment, @invalid_attrs)
      assert comment == Feed.get_comment!(comment.id)
    end

    test "delete_comment/1 deletes the comment" do
      comment = comment_fixture()
      assert {:ok, %Comment{}} = Feed.delete_comment(comment)
      assert_raise Ecto.NoResultsError, fn -> Feed.get_comment!(comment.id) end
    end

    test "change_comment/1 returns a comment changeset" do
      comment = comment_fixture()
      assert %Ecto.Changeset{} = Feed.change_comment(comment)
    end
  end

  describe "post_comment_likes" do
    alias Instagrain.Feed.Post.CommentLike

    import Instagrain.FeedFixtures

    @invalid_attrs %{}

    test "list_post_comment_likes/0 returns all post_comment_likes" do
      comment_like = comment_like_fixture()
      assert Feed.list_post_comment_likes() == [comment_like]
    end

    test "get_comment_like!/1 returns the comment_like with given id" do
      comment_like = comment_like_fixture()
      assert Feed.get_comment_like!(comment_like.id) == comment_like
    end

    test "create_comment_like/1 with valid data creates a comment_like" do
      valid_attrs = %{}

      assert {:ok, %CommentLike{} = comment_like} = Feed.create_comment_like(valid_attrs)
    end

    test "create_comment_like/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Feed.create_comment_like(@invalid_attrs)
    end

    test "update_comment_like/2 with valid data updates the comment_like" do
      comment_like = comment_like_fixture()
      update_attrs = %{}

      assert {:ok, %CommentLike{} = comment_like} =
               Feed.update_comment_like(comment_like, update_attrs)
    end

    test "update_comment_like/2 with invalid data returns error changeset" do
      comment_like = comment_like_fixture()
      assert {:error, %Ecto.Changeset{}} = Feed.update_comment_like(comment_like, @invalid_attrs)
      assert comment_like == Feed.get_comment_like!(comment_like.id)
    end

    test "delete_comment_like/1 deletes the comment_like" do
      comment_like = comment_like_fixture()
      assert {:ok, %CommentLike{}} = Feed.delete_comment_like(comment_like)
      assert_raise Ecto.NoResultsError, fn -> Feed.get_comment_like!(comment_like.id) end
    end

    test "change_comment_like/1 returns a comment_like changeset" do
      comment_like = comment_like_fixture()
      assert %Ecto.Changeset{} = Feed.change_comment_like(comment_like)
    end
  end

  describe "post_saves" do
    alias Instagrain.Feed.Post.Save

    import Instagrain.FeedFixtures

    @invalid_attrs %{}

    test "list_post_saves/0 returns all post_saves" do
      save = save_fixture()
      assert Feed.list_post_saves() == [save]
    end

    test "get_save!/1 returns the save with given id" do
      save = save_fixture()
      assert Feed.get_save!(save.id) == save
    end

    test "create_save/1 with valid data creates a save" do
      valid_attrs = %{}

      assert {:ok, %Save{} = save} = Feed.create_save(valid_attrs)
    end

    test "create_save/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Feed.create_save(@invalid_attrs)
    end

    test "update_save/2 with valid data updates the save" do
      save = save_fixture()
      update_attrs = %{}

      assert {:ok, %Save{} = save} = Feed.update_save(save, update_attrs)
    end

    test "update_save/2 with invalid data returns error changeset" do
      save = save_fixture()
      assert {:error, %Ecto.Changeset{}} = Feed.update_save(save, @invalid_attrs)
      assert save == Feed.get_save!(save.id)
    end

    test "delete_save/1 deletes the save" do
      save = save_fixture()
      assert {:ok, %Save{}} = Feed.delete_save(save)
      assert_raise Ecto.NoResultsError, fn -> Feed.get_save!(save.id) end
    end

    test "change_save/1 returns a save changeset" do
      save = save_fixture()
      assert %Ecto.Changeset{} = Feed.change_save(save)
    end
  end
end
