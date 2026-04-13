defmodule Instagrain.FeedTest do
  use Instagrain.DataCase

  alias Instagrain.Feed
  alias Instagrain.Feed.Post
  alias Instagrain.Feed.Post.Comment
  alias Instagrain.Feed.Post.Resource

  import Instagrain.AccountsFixtures
  import Instagrain.FeedFixtures

  describe "posts" do
    test "list_posts/1 returns all posts for user" do
      user = user_fixture()
      post = post_fixture(%{user: user})
      posts = Feed.list_posts(user.id)
      assert length(posts) == 1
      assert hd(posts).id == post.id
    end

    test "get_post!/2 returns the post with given id" do
      user = user_fixture()
      post = post_fixture(%{user: user})
      fetched = Feed.get_post!(post.id, user.id)
      assert fetched.id == post.id
    end

    test "create_post/1 with valid data creates a post" do
      user = user_fixture()

      valid_attrs = %{
        likes: 0,
        caption: "some caption",
        hide_likes: true,
        disable_comments: true,
        user_id: user.id
      }

      assert {:ok, %Post{} = post} = Feed.create_post(valid_attrs)
      assert post.caption == "some caption"
      assert post.likes == 0
      assert post.hide_likes == true
      assert post.disable_comments == true
      assert post.user_id == user.id
    end

    test "create_post/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Feed.create_post(%{caption: "no user"})
    end

    test "update_post/2 with valid data updates the post" do
      post = post_fixture()
      update_attrs = %{caption: "updated caption", hide_likes: true}

      assert {:ok, %Post{} = updated} = Feed.update_post(post, update_attrs)
      assert updated.caption == "updated caption"
      assert updated.hide_likes == true
    end

    test "update_post/2 with invalid data returns error changeset" do
      user = user_fixture()
      post = post_fixture(%{user: user})
      assert {:error, %Ecto.Changeset{}} = Feed.update_post(post, %{user_id: nil})
      fetched = Feed.get_post!(post.id, user.id)
      assert fetched.id == post.id
    end

    test "delete_post/1 deletes the post" do
      user = user_fixture()
      post = post_fixture(%{user: user})
      assert {:ok, %Post{}} = Feed.delete_post(post)
      assert_raise Ecto.NoResultsError, fn -> Feed.get_post!(post.id, user.id) end
    end

    test "change_post/1 returns a post changeset" do
      post = post_fixture()
      assert %Ecto.Changeset{} = Feed.change_post(post)
    end
  end

  describe "post_resources" do
    test "list_post_resources/0 returns all post_resources" do
      resource = resource_fixture()
      assert Feed.list_post_resources() == [resource]
    end

    test "get_resource!/1 returns the resource with given id" do
      resource = resource_fixture()
      assert Feed.get_resource!(resource.id) == resource
    end

    test "create_resource/1 with valid data creates a resource" do
      post = post_fixture()
      valid_attrs = %{type: :photo, file: "some file", alt: "some alt", post_id: post.id}

      assert {:ok, %Resource{} = resource} = Feed.create_resource(valid_attrs)
      assert resource.type == :photo
      assert resource.file == "some file"
      assert resource.alt == "some alt"
    end

    test "create_resource/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Feed.create_resource(%{type: nil, file: nil, alt: nil})
    end

    test "update_resource/2 with valid data updates the resource" do
      resource = resource_fixture()
      update_attrs = %{type: :video, file: "updated file", alt: "updated alt"}

      assert {:ok, %Resource{} = updated} = Feed.update_resource(resource, update_attrs)
      assert updated.type == :video
      assert updated.file == "updated file"
      assert updated.alt == "updated alt"
    end

    test "update_resource/2 with invalid data returns error changeset" do
      resource = resource_fixture()
      assert {:error, %Ecto.Changeset{}} = Feed.update_resource(resource, %{file: nil})
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

  describe "post_comments" do
    test "list_post_comments/0 returns all post_comments" do
      comment = comment_fixture()
      assert Feed.list_post_comments() == [comment]
    end

    test "get_comment!/1 returns the comment with given id" do
      comment = comment_fixture()
      assert Feed.get_comment!(comment.id) == comment
    end

    test "create_comment/1 with valid data creates a comment" do
      user = user_fixture()
      post = post_fixture(%{user: user})
      valid_attrs = %{comment: "great post!", post_id: post.id, user_id: user.id}

      assert {:ok, %Comment{} = comment} = Feed.create_comment(valid_attrs)
      assert comment.comment == "great post!"
    end

    test "create_comment/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Feed.create_comment(%{comment: nil})
    end

    test "update_comment/2 with valid data updates the comment" do
      comment = comment_fixture()
      update_attrs = %{comment: "updated comment"}

      assert {:ok, %Comment{} = updated} = Feed.update_comment(comment, update_attrs)
      assert updated.comment == "updated comment"
    end

    test "update_comment/2 with invalid data returns error changeset" do
      comment = comment_fixture()
      assert {:error, %Ecto.Changeset{}} = Feed.update_comment(comment, %{comment: nil})
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

  describe "like/unlike" do
    test "like/2 creates a like and increments post likes count" do
      user = user_fixture()
      post = post_fixture(%{user: user})
      liker = user_fixture()

      assert {:ok, %{liked_by_current_user?: true, likes: 1}} = Feed.like(post.id, liker.id)
    end

    test "like/2 fails for duplicate likes" do
      user = user_fixture()
      post = post_fixture(%{user: user})
      liker = user_fixture()

      assert {:ok, _} = Feed.like(post.id, liker.id)
      assert {:error, :like, _, _} = Feed.like(post.id, liker.id)
    end

    test "unlike/2 removes a like and decrements post likes count" do
      user = user_fixture()
      post = post_fixture(%{user: user})
      liker = user_fixture()

      {:ok, _} = Feed.like(post.id, liker.id)
      assert {:ok, %{liked_by_current_user?: false, likes: 0}} = Feed.unlike(post.id, liker.id)
    end
  end

  describe "like_comment/unlike_comment" do
    test "like_comment/2 creates a comment like and increments count" do
      comment = comment_fixture()
      liker = user_fixture()

      assert {:ok, %{liked_by_current_user?: true, likes: 1}} =
               Feed.like_comment(comment.id, liker.id)
    end

    test "like_comment/2 fails for duplicate likes" do
      comment = comment_fixture()
      liker = user_fixture()

      assert {:ok, _} = Feed.like_comment(comment.id, liker.id)
      assert {:error, :comment_like, _, _} = Feed.like_comment(comment.id, liker.id)
    end

    test "unlike_comment/2 removes a comment like and decrements count" do
      comment = comment_fixture()
      liker = user_fixture()

      {:ok, _} = Feed.like_comment(comment.id, liker.id)

      assert {:ok, %{liked_by_current_user?: false, likes: 0}} =
               Feed.unlike_comment(comment.id, liker.id)
    end
  end

  describe "hashtags" do
    test "extract_hashtags/1 extracts unique lowercase tags from caption" do
      assert Feed.extract_hashtags("Hello #World #elixir #world") == ["world", "elixir"]
    end

    test "extract_hashtags/1 returns empty list for nil" do
      assert Feed.extract_hashtags(nil) == []
    end

    test "extract_hashtags/1 returns empty list when no hashtags" do
      assert Feed.extract_hashtags("no tags here") == []
    end

    test "extract_hashtags/1 ignores hashtags embedded in words" do
      assert Feed.extract_hashtags("email#notag but #real") == ["real"]
    end

    test "create_post/1 syncs hashtags from caption" do
      user = user_fixture()

      {:ok, post} =
        Feed.create_post(%{
          caption: "Check out #elixir and #phoenix",
          user_id: user.id,
          likes: 0,
          hide_likes: false,
          disable_comments: false
        })

      assert post.id

      elixir_tag = Feed.get_hashtag_by_name("elixir")
      phoenix_tag = Feed.get_hashtag_by_name("phoenix")

      assert elixir_tag != nil
      assert phoenix_tag != nil
      assert elixir_tag.post_count == 1
      assert phoenix_tag.post_count == 1
    end

    test "create_post/1 with no hashtags does not create any" do
      user = user_fixture()

      {:ok, _post} =
        Feed.create_post(%{
          caption: "No tags here",
          user_id: user.id,
          likes: 0,
          hide_likes: false,
          disable_comments: false
        })

      assert Feed.search_hashtags("no") == []
    end

    test "update_post/2 updates hashtag links and counts" do
      user = user_fixture()

      {:ok, post} =
        Feed.create_post(%{
          caption: "Love #elixir",
          user_id: user.id,
          likes: 0,
          hide_likes: false,
          disable_comments: false
        })

      assert Feed.get_hashtag_by_name("elixir").post_count == 1

      {:ok, _updated} = Feed.update_post(post, %{caption: "Love #phoenix"})

      # elixir count decremented, phoenix incremented
      elixir_tag = Feed.get_hashtag_by_name("elixir")
      assert elixir_tag.post_count == 0

      phoenix_tag = Feed.get_hashtag_by_name("phoenix")
      assert phoenix_tag.post_count == 1
    end

    test "delete_post/1 decrements hashtag counts" do
      user = user_fixture()

      {:ok, post} =
        Feed.create_post(%{
          caption: "Bye #elixir",
          user_id: user.id,
          likes: 0,
          hide_likes: false,
          disable_comments: false
        })

      assert Feed.get_hashtag_by_name("elixir").post_count == 1

      Feed.delete_post(post)

      assert Feed.get_hashtag_by_name("elixir").post_count == 0
    end

    test "search_hashtags/2 returns matching hashtags ordered by post_count" do
      user = user_fixture()

      # Create posts to generate hashtags with different counts
      for _ <- 1..3 do
        Feed.create_post(%{
          caption: "#coding is fun",
          user_id: user.id,
          likes: 0,
          hide_likes: false,
          disable_comments: false
        })
      end

      Feed.create_post(%{
        caption: "#coder life",
        user_id: user.id,
        likes: 0,
        hide_likes: false,
        disable_comments: false
      })

      results = Feed.search_hashtags("cod")
      assert length(results) == 2
      assert hd(results).name == "coding"
      assert hd(results).post_count == 3
    end

    test "search_hashtags/2 excludes hashtags with zero post_count" do
      user = user_fixture()

      {:ok, post} =
        Feed.create_post(%{
          caption: "#temp tag",
          user_id: user.id,
          likes: 0,
          hide_likes: false,
          disable_comments: false
        })

      Feed.delete_post(post)

      assert Feed.search_hashtags("temp") == []
    end

    test "list_posts_by_hashtag/4 returns posts for a given tag" do
      user = user_fixture()

      {:ok, post1} =
        Feed.create_post(%{
          caption: "#elixir rocks",
          user_id: user.id,
          likes: 0,
          hide_likes: false,
          disable_comments: false
        })

      {:ok, _post2} =
        Feed.create_post(%{
          caption: "#phoenix framework",
          user_id: user.id,
          likes: 0,
          hide_likes: false,
          disable_comments: false
        })

      posts = Feed.list_posts_by_hashtag("elixir", user.id)
      assert length(posts) == 1
      assert hd(posts).id == post1.id
    end

    test "list_posts_by_hashtag/4 is case-insensitive" do
      user = user_fixture()

      {:ok, _post} =
        Feed.create_post(%{
          caption: "#Elixir rocks",
          user_id: user.id,
          likes: 0,
          hide_likes: false,
          disable_comments: false
        })

      posts = Feed.list_posts_by_hashtag("ELIXIR", user.id)
      assert length(posts) == 1
    end

    test "get_hashtag_by_name/1 returns hashtag or nil" do
      user = user_fixture()

      Feed.create_post(%{
        caption: "#elixir",
        user_id: user.id,
        likes: 0,
        hide_likes: false,
        disable_comments: false
      })

      assert %Instagrain.Feed.Hashtag{name: "elixir"} = Feed.get_hashtag_by_name("elixir")
      assert %Instagrain.Feed.Hashtag{name: "elixir"} = Feed.get_hashtag_by_name("ELIXIR")
      assert Feed.get_hashtag_by_name("nonexistent") == nil
    end

    test "multiple posts share the same hashtag record" do
      user = user_fixture()

      Feed.create_post(%{
        caption: "#shared",
        user_id: user.id,
        likes: 0,
        hide_likes: false,
        disable_comments: false
      })

      Feed.create_post(%{
        caption: "#shared again",
        user_id: user.id,
        likes: 0,
        hide_likes: false,
        disable_comments: false
      })

      tag = Feed.get_hashtag_by_name("shared")
      assert tag.post_count == 2
    end
  end

  describe "save_post/remove_save_post" do
    test "save_post/2 saves a post for a user" do
      user = user_fixture()
      post = post_fixture(%{user: user})
      saver = user_fixture()

      assert {:ok, save} = Feed.save_post(post.id, saver.id)
      assert save.post_id == post.id
      assert save.user_id == saver.id
    end

    test "save_post/2 fails for duplicate saves" do
      user = user_fixture()
      post = post_fixture(%{user: user})
      saver = user_fixture()

      assert {:ok, _} = Feed.save_post(post.id, saver.id)
      assert {:error, _} = Feed.save_post(post.id, saver.id)
    end

    test "remove_save_post/2 removes a saved post" do
      user = user_fixture()
      post = post_fixture(%{user: user})
      saver = user_fixture()

      {:ok, _} = Feed.save_post(post.id, saver.id)
      assert :ok = Feed.remove_save_post(post.id, saver.id)
    end

    test "remove_save_post/2 returns error when not saved" do
      user = user_fixture()
      post = post_fixture(%{user: user})

      assert {:error, :not_found} = Feed.remove_save_post(post.id, user.id)
    end
  end
end
