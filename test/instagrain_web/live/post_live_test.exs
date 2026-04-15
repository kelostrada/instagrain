defmodule InstagrainWeb.PostLiveTest do
  use InstagrainWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Instagrain.FeedFixtures

  setup :register_and_log_in_user

  describe "Index" do
    test "renders the feed", %{conn: conn, user: user} do
      author = Instagrain.AccountsFixtures.user_fixture()
      Instagrain.Profiles.follow_user(user.id, author.id)
      post = post_fixture(%{user: author, caption: "Hello world"})

      {:ok, _live, html} = live(conn, ~p"/")

      assert html =~ post.caption
    end

    test "shows empty feed when no posts", %{conn: conn} do
      {:ok, _live, _html} = live(conn, ~p"/")
    end

    test "renders double-tap like target on post images", %{conn: conn, user: user} do
      author = Instagrain.AccountsFixtures.user_fixture()
      Instagrain.Profiles.follow_user(user.id, author.id)
      post = post_fixture(%{user: author, caption: "Tap me"})
      resource_fixture(%{post: post})

      {:ok, _live, html} = live(conn, ~p"/")

      assert html =~ "post-dbl-tap-#{post.id}"
      assert html =~ "data-target=\"post-icons-#{post.id}-root\""
      assert html =~ "data-heart-overlay"
    end
  end

  describe "Show" do
    test "displays a post", %{conn: conn, user: user} do
      post = post_fixture(%{user: user, caption: "Test post"})

      {:ok, _live, html} = live(conn, ~p"/p/#{post.id}")

      assert html =~ "Test post"
    end

    test "displays post with location", %{conn: conn, user: user} do
      location = location_fixture(%{name: "Warsaw, Poland"})
      post = post_fixture(%{user: user, caption: "In Warsaw", location_id: location.id})

      {:ok, _live, html} = live(conn, ~p"/p/#{post.id}")

      assert html =~ "Warsaw, Poland"
    end

    test "like and unlike a post", %{conn: conn} do
      author = Instagrain.AccountsFixtures.user_fixture()
      post = post_fixture(%{user: author, caption: "Like this"})

      {:ok, live, html} = live(conn, ~p"/p/#{post.id}")

      # Initially not liked
      assert html =~ "hero-heart"
      refute html =~ "bg-red-500"

      # Like the post via the icons component
      live
      |> element("#post-details-icons-#{post.id}-root [phx-click='like']")
      |> render_click()

      html = render(live)
      assert html =~ "bg-red-500"
      assert html =~ "1 like"

      # Unlike the post
      live
      |> element("#post-details-icons-#{post.id}-root [phx-click='unlike']")
      |> render_click()

      html = render(live)
      refute html =~ "bg-red-500"
    end
  end
end
